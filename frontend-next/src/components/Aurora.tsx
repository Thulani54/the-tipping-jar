// Animated aurora blobs — a soft, living colour field that sits behind the
// glass cards so their frosted blur has something green to refract. Pure CSS
// (see .aurora / .blob in globals.css); decorative only.

export function Aurora({ className = "" }: { className?: string }) {
  return (
    <div className={`aurora ${className}`} aria-hidden>
      <span
        className="blob"
        style={{ width: 400, height: 400, top: "-10%", left: "-6%", background: "var(--mint)", animationDelay: "0s" }}
      />
      <span
        className="blob"
        style={{ width: 340, height: 340, top: "26%", right: "-8%", background: "var(--green)", animationDelay: "-7s" }}
      />
      <span
        className="blob"
        style={{ width: 280, height: 280, bottom: "-12%", left: "34%", background: "var(--gold)", opacity: 0.32, animationDelay: "-13s" }}
      />
    </div>
  );
}
