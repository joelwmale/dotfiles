---
name: dark-mode-image
description: Create dark-mode variants of raster images for dark UI contexts.
---

# Dark Mode Image

Use this when the user wants to adapt a standalone source image into a dark-mode-suitable version.

## Activation

### Use For

- creating a dark-mode version of an image, illustration, screenshot, photo, product mockup, decorative background, or texture
- adapting an existing raster image so it presents correctly on a dark background
- generating a dark-mode image variant for use in a dark-mode UI

### Do Not Use For

- adding dark mode to a page, section, component, or site
- SVG-only assets
- general image styling in a UI without dark-mode conversion

When the `add-dark-mode` skill identifies raster images that need dark-mode variants, use this skill for that image-generation work. This skill is the required handoff point between dark-mode UI work and raster image generation.

## Load First

- Generate or edit the image with whatever image tool is available in this session. If none is available, say so and stop - do not approximate with CSS filters.

## Progress Updates

Keep the user informed so longer runs do not look stuck.

- One-line status update before each major phase.
- Concrete and lightweight: what you are doing now, not verbose logs.

## Workflow

1. Inspect the source image and the dark-mode UI context.
2. Generate or edit a dark-mode version with the same dimensions as the original.
3. Save the dark-mode image with a `-dark` suffix alongside the original.
4. Return the saved project path for the caller to wire into the UI.

## Rules

- When generating a dark-mode image, choose a background color that feels like an appropriate inversion of the original background color: black or dark gray for white, dark gray for off-white, or the specific dark color provided by the user; if the original image's background matched the site background, match the dark-mode site background instead
- Preserve the same contrast characteristics as the original image; light sections should become darker while relative separation and readability stay intact
- Preserve blurs and softness; never sharpen anything that was blurry in the original image
- Preserve the foreground color palette hues, adjusting saturation and lightness only as needed so the image presents correctly on a dark background
- Preserve the original vibe as much as possible: bright and intense images should stay bright and intense, while subtle and muted images should stay subtle and muted
- Pay attention to areas that fade out and preserve those fades in the dark-mode version
- The generated dark-mode image must be exactly the same dimensions as the original image
- Save dark-mode images with a `-dark` suffix, for example `bg.jpg` and `bg-dark.jpg`

## Verify

- Confirm the generated image dimensions match the original exactly.
- Confirm the dark-mode image preserves the original composition, softness, fades, and foreground palette.
