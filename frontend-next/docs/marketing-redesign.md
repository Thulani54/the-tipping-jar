# Pantri-inspired local redesign

Reference: https://pantri.africa/ (visually inspected 26 September 2026).
The reference's computed font is Manrope. Tipping Jar already loads Manrope through next/font; this redesign keeps that font and uses lighter 500-weight display headings.

Design: photographic navy hero, orange pill CTAs, white and blue-grey surfaces, thin outline icons, generous spacing. Shared marketing styling lives in src/app/marketing.css. Creator directory listings remain hidden. Dashboard routes retain their existing app shell.

Local run: `PREVIEW_HTTP=1 npm run dev -- --hostname 127.0.0.1 --port 3000` from frontend-next. Existing API configuration remains in place. The landing page uses illustrative previews and makes no payment requests. The dashboard graphic is explicitly labelled Example.

Hero asset: public/creator-studio-hero.webp, generated with the built-in image generation tool and optimised to WebP (114 KB). Original source retained under the Codex generated-images folder. It depicts a fictional creator, not an actual customer or endorsement.

Generation prompt:
Create a polished photorealistic editorial website hero photograph, widescreen 1536x1024. A joyful Black South African female podcaster and musician in her late twenties, natural curly hair tied up, wearing over-ear black headphones and a warm ivory textured shirt, seated at a desk in a beautiful warm recording studio. Professional black broadcast microphone on a boom arm in foreground, acoustic panels, warm amber natural late afternoon sunlight. Subject entirely in RIGHT HALF of frame, medium waist-up view with face at upper-right third, candid happy smile looking slightly toward microphone. LEFT HALF of image is mostly uncluttered very dark navy studio wall, clean negative space for website headline. Cinematic but natural authentic texture, aspirational independent creator energy. No text, no logos, no watermark. Landscape composition.

Validation: Next production build and TypeScript passed. Browser verified desktop and mobile layouts, tip amount selection, audience tabs, FAQ expansion, and mobile navigation to Features. No production deployment performed.
