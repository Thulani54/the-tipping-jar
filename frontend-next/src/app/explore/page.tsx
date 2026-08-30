import { redirect } from "next/navigation";

// Duplicate of the old /creators grid — hidden during private beta the
// same way. Send anyone hitting /explore to the /creators waitlist
// landing rather than showing an unvetted grid here.
export default function ExplorePage() {
  redirect("/creators");
}
