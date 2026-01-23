# Component Naming

PascalCase files, kebab-case in templates.

| File | Template Usage |
|------|----------------|
| `AppBar.vue` | `<app-bar />` |
| `ToggleThemeButton.vue` | `<toggle-theme-button />` |
| `LocaleSwitcher.vue` | `<locale-switcher />` |

**Why:**
- Vue style guide convention for SFCs
- Auto-import (unplugin-vue-components) resolves PascalCase → kebab-case
- HTML is case-insensitive; kebab-case works reliably in templates

**Pattern:**
- File names: `PascalCase.vue` in `components/`
- Template usage: `<kebab-case />`
- No manual imports needed—components auto-imported
- Multi-word names required (avoid single-word like `Button.vue`)
