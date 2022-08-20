# vimuri

Adds a `vim://` URI scheme.

### `vim://opt/*`: Options

**Available options:**
- `runtimepath`, `rtp`
- `packpath`, `pp`
- `path`, `pa`
- `tags`, `tag`
- `wildignore`, `wig`

**Alias:** `vim://&rtp` resolves to `vim://opt/runtimepath`

### `vim://reg/*`: Registers

**Available registers:**
- `"` - unnamed register (NOTE: has to be escaped with a backslash, ie. `:e vim://reg/\"`)
- `a-z` - named registers
- `0-9` - numbered registers

**Alias:** `vim://@q` resolves to `vim://reg/q`
