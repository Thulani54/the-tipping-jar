#!/usr/bin/env python3
"""
Nightly daily-tips report.

Runs at 00:00 SAST (22:00 UTC via cron). For the just-ended SAST day, finds
every creator who received at least one completed tip, renders a styled PDF of
that day's transactions, and emails it to the creator.

    python daily_report.py                 # live: yesterday (SAST)
    python daily_report.py --dry-run       # print only, no emails
    python daily_report.py --date 2026-07-20
    python daily_report.py --to you@x.com  # force all reports to one address (testing)

Reads the Rust services' Postgres databases (tips_db, creators_db, accounts_db)
on the shared instance. SMTP + DB config come from the environment.
"""
import datetime
import os
import smtplib
import sys
from collections import defaultdict
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from zoneinfo import ZoneInfo

import psycopg2
from fpdf import FPDF

SAST = ZoneInfo("Africa/Johannesburg")

DB_HOST = os.environ.get("DB_HOST", "db")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_USER = os.environ.get("POSTGRES_USER", "postgres")
DB_PASS = os.environ.get("POSTGRES_PASSWORD", "postgres")

SMTP_HOST = os.environ.get("SMTP_HOST", "")
SMTP_PORT = int(os.environ.get("SMTP_PORT", "587"))
SMTP_USER = os.environ.get("SMTP_USER", "")
SMTP_PASS = os.environ.get("SMTP_PASS", "")
SMTP_FROM = os.environ.get("SMTP_FROM", SMTP_USER or "no-reply@tippingjar.co.za")

# Brand palette (RGB)
NAVY = (15, 36, 57)
MINT = (87, 206, 139)
GOLD = (224, 165, 54)
GREEN = (18, 162, 92)
INK = (15, 36, 57)
MUTED = (90, 107, 123)
LINE = (226, 231, 227)
CANVAS = (239, 242, 240)


def db(name):
    return psycopg2.connect(host=DB_HOST, port=DB_PORT, dbname=name, user=DB_USER, password=DB_PASS)


def money(v):
    return f"R{float(v):,.2f}"


def arg(flag):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else None


# ── PDF ──────────────────────────────────────────────────────────────────────

def build_pdf(display, date_label, tips, gross, net):
    pdf = FPDF(orientation="P", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.add_page()
    W = 210
    M = 16
    inner = W - 2 * M

    # Header band
    pdf.set_fill_color(*NAVY)
    pdf.rect(0, 0, W, 34, "F")
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("Helvetica", "B", 22)
    pdf.set_xy(M, 9)
    pdf.cell(0, 9, "Tipping Jar")
    pdf.set_font("Helvetica", "", 11)
    pdf.set_xy(M, 20)
    pdf.cell(0, 6, "Daily tips report")
    pdf.set_font("Helvetica", "", 10)
    pdf.set_xy(0, 13)
    pdf.set_text_color(*MINT)
    pdf.cell(W - M, 6, date_label, align="R")

    # Creator
    pdf.set_text_color(*INK)
    pdf.set_font("Helvetica", "B", 16)
    pdf.set_xy(M, 44)
    pdf.cell(0, 8, display)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(*MUTED)
    pdf.set_xy(M, 52)
    pdf.cell(0, 6, f"{len(tips)} tip(s) received")

    # Summary tiles
    y = 62
    tiles = [("Tips", str(len(tips))), ("Gross", money(gross)), ("You receive", money(net))]
    tw = (inner - 2 * 4) / 3
    for i, (label, val) in enumerate(tiles):
        x = M + i * (tw + 4)
        pdf.set_fill_color(*CANVAS)
        pdf.set_draw_color(*LINE)
        pdf.rect(x, y, tw, 22, "DF")
        pdf.set_xy(x + 5, y + 4)
        pdf.set_text_color(*MUTED)
        pdf.set_font("Helvetica", "", 8)
        pdf.cell(tw - 10, 4, label.upper())
        pdf.set_xy(x + 5, y + 9)
        pdf.set_text_color(*(GREEN if i == 2 else INK))
        pdf.set_font("Helvetica", "B", 15)
        pdf.cell(tw - 10, 8, val)

    # Table
    y = 92
    cols = [("Time", 18), ("Supporter", 40), ("Message", 68), ("Amount", 26), ("You get", 26)]
    pdf.set_xy(M, y)
    pdf.set_fill_color(*NAVY)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("Helvetica", "B", 9)
    x = M
    for name, w in cols:
        align = "R" if name in ("Amount", "You get") else "L"
        pdf.set_xy(x, y)
        pdf.cell(w, 9, f" {name}", align=align, fill=True)
        x += w
    y += 9

    pdf.set_font("Helvetica", "", 9)
    for idx, t in enumerate(tips):
        if y > 270:
            pdf.add_page()
            y = 18
        pdf.set_fill_color(255, 255, 255) if idx % 2 == 0 else pdf.set_fill_color(247, 249, 248)
        pdf.rect(M, y, inner, 8, "F")
        pdf.set_draw_color(*LINE)
        pdf.line(M, y + 8, M + inner, y + 8)
        row = [
            t["time"],
            (t["tipper"] or "Anonymous")[:22],
            (t["message"] or "")[:40],
            money(t["amount"]),
            money(t["net"]),
        ]
        x = M
        for (name, w), val in zip(cols, row):
            align = "R" if name in ("Amount", "You get") else "L"
            pdf.set_xy(x, y)
            pdf.set_text_color(*(GREEN if name == "You get" else INK if name == "Amount" else MUTED if name in ("Time", "Message") else INK))
            pdf.set_font("Helvetica", "B" if name in ("Amount", "You get", "Supporter") else "", 9)
            pdf.cell(w, 8, f" {val} " if align == "L" else f"{val} ", align=align)
            x += w
        y += 8

    # Totals
    pdf.set_xy(M, y + 1)
    pdf.set_fill_color(*CANVAS)
    pdf.rect(M, y + 1, inner, 10, "F")
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(*INK)
    pdf.set_xy(M, y + 1)
    pdf.cell(126, 10, "Total  ", align="R")  # spans Time+Supporter+Message
    pdf.cell(26, 10, money(gross), align="R")
    pdf.set_text_color(*GREEN)
    pdf.cell(26, 10, f"{money(net)} ", align="R")

    # Footer
    pdf.set_y(-16)
    pdf.set_font("Helvetica", "", 8)
    pdf.set_text_color(*MUTED)
    pdf.cell(0, 6, "Generated by Tipping Jar  ·  tippingjar.co.za  ·  This is a summary, not a tax invoice.", align="C")

    return bytes(pdf.output())


# ── Email ────────────────────────────────────────────────────────────────────

def email_html(display, date_label, tips, gross, net):
    rows = "".join(
        f"<tr><td style='padding:8px 4px;color:#5a6b7b;font-size:13px'>{t['time']}</td>"
        f"<td style='padding:8px 4px;font-weight:600'>{(t['tipper'] or 'Anonymous')}</td>"
        f"<td style='padding:8px 4px;text-align:right;font-weight:700;color:#12a25c'>{money(t['amount'])}</td></tr>"
        for t in tips[:8]
    )
    more = f"<p style='color:#5a6b7b;font-size:13px'>+ {len(tips)-8} more in the attached PDF</p>" if len(tips) > 8 else ""
    return f"""\
<div style="font-family:Arial,Helvetica,sans-serif;background:#eff2f0;padding:24px">
  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e2e7e3">
    <div style="background:#0f2439;padding:24px 28px;color:#fff">
      <div style="font-size:20px;font-weight:800">Tipping Jar</div>
      <div style="opacity:.8;font-size:14px;margin-top:2px">Daily tips report · {date_label}</div>
    </div>
    <div style="padding:24px 28px">
      <p style="margin:0 0 6px;font-size:16px">Hi {display},</p>
      <p style="margin:0 0 18px;color:#5a6b7b">You received <b>{len(tips)} tip(s)</b> yesterday. Here's the rundown — the full styled statement is attached as a PDF.</p>
      <div style="display:flex;gap:12px;margin-bottom:18px">
        <div style="flex:1;background:#eff2f0;border-radius:12px;padding:14px">
          <div style="font-size:11px;color:#5a6b7b;text-transform:uppercase;letter-spacing:1px">Gross</div>
          <div style="font-size:22px;font-weight:800;color:#0f2439">{money(gross)}</div>
        </div>
        <div style="flex:1;background:#eff2f0;border-radius:12px;padding:14px">
          <div style="font-size:11px;color:#5a6b7b;text-transform:uppercase;letter-spacing:1px">You receive</div>
          <div style="font-size:22px;font-weight:800;color:#12a25c">{money(net)}</div>
        </div>
      </div>
      <table style="width:100%;border-collapse:collapse;border-top:1px solid #e2e7e3">{rows}</table>
      {more}
      <a href="https://www.tippingjar.co.za/dashboard" style="display:inline-block;margin-top:20px;background:#0f2439;color:#fff;text-decoration:none;padding:12px 22px;border-radius:999px;font-weight:600">View your dashboard</a>
    </div>
    <div style="padding:16px 28px;color:#8a97a4;font-size:12px;border-top:1px solid #e2e7e3">
      You're receiving this because you have an active Tipping Jar creator page.
    </div>
  </div>
</div>"""


def send_email(to_addr, display, date_label, tips, gross, net, pdf_bytes):
    msg = MIMEMultipart("mixed")
    msg["Subject"] = f"Your Tipping Jar report — {money(net)} from {len(tips)} tip(s) · {date_label}"
    msg["From"] = SMTP_FROM
    msg["To"] = to_addr
    alt = MIMEMultipart("alternative")
    alt.attach(MIMEText(f"You received {len(tips)} tip(s) totalling {money(gross)} ({money(net)} to you) on {date_label}. See the attached PDF.", "plain"))
    alt.attach(MIMEText(email_html(display, date_label, tips, gross, net), "html"))
    msg.attach(alt)
    pdf = MIMEApplication(pdf_bytes, _subtype="pdf")
    pdf.add_header("Content-Disposition", "attachment", filename=f"tipping-jar-report-{date_label.replace(' ', '-')}.pdf")
    msg.attach(pdf)

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=20) as s:
        s.starttls()
        s.login(SMTP_USER, SMTP_PASS)
        s.sendmail(SMTP_FROM, [to_addr], msg.as_string())


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    dry = "--dry-run" in sys.argv
    force_to = arg("--to")
    date_arg = arg("--date")
    report_date = (
        datetime.date.fromisoformat(date_arg)
        if date_arg
        else datetime.datetime.now(SAST).date() - datetime.timedelta(days=1)
    )
    start = datetime.datetime.combine(report_date, datetime.time.min, tzinfo=SAST).astimezone(datetime.timezone.utc)
    end = start + datetime.timedelta(days=1)
    date_label = report_date.strftime("%a %d %b %Y")
    print(f"[daily_report] {date_label}  {start} -> {end}  dry={dry} to={force_to or 'creators'}")

    tc = db("tips_db")
    cur = tc.cursor()
    cur.execute(
        """SELECT creator_id, creator_name, tipper_name, amount, message, creator_net, created_at
           FROM tips WHERE status='completed' AND created_at >= %s AND created_at < %s
           ORDER BY creator_id, created_at""",
        (start, end),
    )
    rows = cur.fetchall()
    tc.close()

    if not rows:
        print("No completed tips for that day. Nothing to send.")
        return

    by_creator = defaultdict(list)
    names = {}
    for cid, cname, tipper, amount, message, net, created in rows:
        by_creator[cid].append(
            {"tipper": tipper, "amount": amount, "message": message, "net": net,
             "time": created.astimezone(SAST).strftime("%H:%M")}
        )
        names[cid] = cname or "Creator"

    # creator_id -> user_id -> email
    cc = db("creators_db")
    cur = cc.cursor()
    cur.execute(
        "SELECT id, user_id, display_name FROM creator_profiles WHERE id = ANY(%s::uuid[])",
        ([str(k) for k in by_creator.keys()],),
    )
    cmeta = {r[0]: {"user_id": r[1], "display": r[2]} for r in cur.fetchall()}
    cc.close()
    ac = db("accounts_db")
    cur = ac.cursor()
    cur.execute(
        "SELECT id, email FROM users WHERE id = ANY(%s::uuid[])",
        ([str(m["user_id"]) for m in cmeta.values()],),
    )
    emails = {r[0]: r[1] for r in cur.fetchall()}
    ac.close()

    out_dir = arg("--out")  # write PDFs to a dir instead of emailing (preview/debug)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    sent = 0
    for cid, tips in by_creator.items():
        meta = cmeta.get(cid, {})
        display = meta.get("display") or names.get(cid, "Creator")
        email = force_to or emails.get(meta.get("user_id"))
        gross = sum(float(t["amount"]) for t in tips)
        net = sum(float(t["net"]) for t in tips)
        print(f"  {display}: {len(tips)} tip(s), {money(gross)} -> {email or '(no email)'}")
        try:
            pdf = build_pdf(display, date_label, tips, gross, net)
            if out_dir:
                safe = "".join(c if c.isalnum() else "_" for c in display) or "creator"
                path = os.path.join(out_dir, f"{safe}-{report_date}.pdf")
                with open(path, "wb") as f:
                    f.write(pdf)
                print(f"    wrote {path}")
                sent += 1
                continue
            if dry or not email:
                continue
            send_email(email, display, date_label, tips, gross, net, pdf)
            sent += 1
        except Exception as exc:  # noqa
            print(f"  ! failed for {display}: {exc}")

    print(f"Done. {'Rendered' if out_dir else 'Would send' if dry else 'Sent'} {sent} report(s).")


if __name__ == "__main__":
    main()
