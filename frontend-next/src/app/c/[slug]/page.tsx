import { redirect } from "next/navigation";

// Alias of the creator page: /c/<slug> → /creator/<slug>
export default async function Page({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  redirect(`/creator/${slug}`);
}
