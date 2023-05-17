<!-- DOCGEN_IGNORE_START -->

<!-- This tag controlls what's ignored by the docgen workflow. -->

![Linting Status](https://img.shields.io/github/actions/workflow/status/kndndrj/nvim-dbee/lint.yml?label=linting&style=for-the-badge)
![Docgen Status](https://img.shields.io/github/actions/workflow/status/kndndrj/nvim-dbee/docgen.yml?label=docgen&logo=neovim&logoColor=white&style=for-the-badge)
![Backend](https://img.shields.io/badge/go-backend-lightblue?style=for-the-badge&logo=go&logoColor=white)
![Frontend](https://img.shields.io/badge/lua-frontend-blue?style=for-the-badge&logo=lua&logoColor=white)

<!-- DOCGEN_IGNORE_END -->

# Neovim DBee

**Database Client for NeoVim!**

**Execute Your Favourite Queries From the Comfort of Your Editor!**

**Backend in Go!**

**Frontend in Lua!**

**Get Results FAST With Under-the-hood Iterator!**

**Integrates with nvim-projector!**

**Bees Love It!**

***Alpha Software - Expect Breaking Changes!***

## Installation

- packer.nvim:

  ```lua
  use {
    "kndndrj/nvim-dbee",
    requires = {
      "MunifTanjim/nui.nvim",
    },
    run = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup(--[[optional config]])
    end
  }
  ```

- lazy.nvim:

  ```lua
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      require("dbee").install()
    end,
    config = function()
      require("dbee").setup(--[[optional config]])
    end,
  },
  ```

### Platform Support

<!-- DOCGEN_IGNORE_START -->

<details>
  <summary>Click to expand</summary>
<!-- DOCGEN_IGNORE_END -->

This project aims to be as cross-platform as possible, but there are some
limitations (for example some of the go dependencies only work on certain
platforms).

The CI pipeline tries building the binary for all possible GOARCH/GOOS
combinations - the ones that succeed are stored in a
[remote bucket](https://github.com/kndndrj/nvim-dbee-bucket) on it's own branch.
Additionally, the [install manifest](lua/dbee/install/__manifest.lua) gets
created.

So to check if your platform is currently supported, check out the mentioned
manifest

<!-- DOCGEN_IGNORE_START -->

</details>
<!-- DOCGEN_IGNORE_END -->

### Manual Binary Installation

<!-- DOCGEN_IGNORE_START -->

<details>
  <summary>Click to expand</summary>
<!-- DOCGEN_IGNORE_END -->

The installation examples include the `build`/`run` functions, which get
triggered once the plugin updates. This should be sufficient for the majority of
users. If that doesn't include you, then you have a few options:

- just install with the `"go"` option (this performs `go install` under the
  hood):
  ```lua
  require("dbee").install("go")
  ```
- Download an already compiled binary from one of urls in the
  [install manifest](lua/dbee/install/__manifest.lua)
- `go install` (the install location will vary depending on your local go
  configuration):
  ```sh
  go install github.com/kndndrj/nvim-dbee/dbee@<version>
  ```
- Clone and build
  ```sh
  # Clone the repository and cd into the "go subfolder"
  git clone <this_repo>
  cd <this_repo>/dbee
  # Build the binary (optional output path)
  go build [-o ~/.local/share/nvim/dbee/bin/dbee]
  ```

<!-- DOCGEN_IGNORE_START -->

</details>
<!-- DOCGEN_IGNORE_END -->

## Configuration

You can pass an optional table parameter to `setup()` function.

Here are the defaults:

<!--DOCGEN_CONFIG_START-->

<!-- Contents from lua/dbee/config.lua are inserted between these tags for docgen. -->

[`config.lua`](lua/dbee/config.lua)

<!--DOCGEN_CONFIG_END-->

## Usage

Call the `setup()` function with an optional config parameter. If you are not
using your plugin manager to lazy load for you, make sure to specify
`{ lazy = true }` in the config.

<!-- DOCGEN_IGNORE_START -->

<details>
  <summary>Brief reference (click to expand):</summary>
<!-- DOCGEN_IGNORE_END -->

```lua
-- Open/close the UI.
require("dbee").open()
require("dbee").close()
-- Next/previou page of the results (there are the same mappings that work just inside the results buffer
-- available in config).
require("dbee").next()
require("dbee").prev()
-- Run a query on the active connection directly.
require("dbee").execute(query)
-- Save the current result to file (format is either "csv" or "json" for now).
require("dbee").save(format, file)
```

<!-- DOCGEN_IGNORE_START -->

</details>
<!-- DOCGEN_IGNORE_END -->

### Getting Started

Here are a few steps to quickly get started:

- call the `setup()` function in your `init.lua`

- Specify connections using one or more sources (reffer to
  [this section](#specifying-connections)).

- When you restart the editor, call `lua require("dbee").open()` to open the UI.

- Navigate to the drawer (tree) and use the following key-bindings to perform
  different actions depending on the context (the mappings can all be changed in
  the config):

  - All nodes:

    - Press `o` to toggle the tree node, `e` to expand and `c` to close.
    - Press `r` to manually refresh the tree.

  - Connections:

    - Press `da` to set it as the active one.
    - Press `dd` to delete it (this also triggers the `remove` function - see
      more below.)
    - Press `<CR>` to perform an action - view history or look at helper
      queries.

  - Scratchpads:

    - Press `<CR>` on the `new` node to create a new scratchpad.
    - When you try to save it to disk (`:w`), the path is automatically filled
      for you. You can change the name to anything you want, if you save it to
      the suggested directory, it will load the next time you open DBee.
    - Press `da` to rename the scratchpad.
    - Press `dd` to delete it (also from disk).
    - Pressing `<CR>` on an existing scratchpad in the drawer will open it in
      the editor pane.

  - Help:

    - Just view the key bindings.

- Once you selected the connection and created a scratchpad, you can navigate to
  the editor pane (top-right by default) and start writing queries. In editor
  pane, you can use the following actions:

  - Highlight some text in visual mode and press `BB` - this will run the
    selected query on the active connection.
  - If you press `BB` in normal mode, you run the whole scratchpad on the active
    connection.

- If the request was successful, the results should appear in the "result"
  buffer (bottom one by default). If the total number of results was lower than
  the `page_size` parameter in config (100 by default), all results should
  already be present. If there are more than `page_size` results, you can "page"
  thrugh them using one of the following:

  - Using `require("dbee").next()` and `require("dbee").prev()` from anywhere
    (even if your cursor is outside the result buffer).
  - Using `L` for next and `H` for previous page if the cursor is located inside
    the results buffer.

- The current result (of the active connection) can also be saved to a file
  using `require("dbee").save()` command. Use:

  - `require("dbee").save("csv", "/path/to/file.csv")` for csv and
  - `require("dbee").save("json", "/path/to/file.json")` for json.

- Once you are done or you want to go back to where you were, you can call
  `require("dbee").close()`.

### Specifying Connections

Connection represents an instance of the database client (i.e. one database).
This is how it looks like:

```lua
{
  id = "optional_identifier" -- useful to set manually if you want to remove from the file (see below)
                             -- IT'S YOUR JOB TO KEEP THESE UNIQUE!
  name = "My Database",
  type = "sqlite", -- type of database driver
  url = "~/path/to/mydb.db",
}
```

There are a few different ways you can use to specify the connection parameters
for DBee:

- Using the `setup()` function:

  The most straightforward (but probably the most useless) way is to just add
  them to your configuration in `init.lua` like this:

  ```lua
  require("dbee").setup {
  connections = {
    {
      name = "My Database",
      type = "sqlite", -- type of database driver
      url = "~/path/to/mydb.db",
    },
    -- ...
  },
  -- ... the rest of your config
  }
  ```

- Use the prompt at runtime:

  You can add connections manually using the "add connection" item in the
  drawer. Fill in the values and write the buffer (`:w`) to save the connection.
  By default, this will save the connection to the global connections file and
  will persist over restarts.

- Use an env variable. This variable is `DBEE_CONNECTIONS` by default:

  You can export an environment variable with connections from your shell like
  this:

  ```sh
    export DBEE_CONNECTIONS='[
        {
            "name": "DB from env",
            "url": "mysql://...",
            "type": "mysql"
        }
    ]'
  ```

- Use a custom load function:

  If you aren't satisfied with the default capabilities, you can provide your
  own `load` function in the config at setup. This example uses a
  project-specific connections config file:

  ```lua
  local file = vim.fn.getcwd() .. "/.dbee.json"

  require("dbee").setup {
    loader = {
      -- this function must return a list of connections and it doesn't
      -- care about anything else
      load = function()
        return require("dbee.loader").load_from_file(file)
      end,
      -- just as an example you can also specify this function to save any
      -- connections from the prompt input to the same file as they are being loaded from
      add = function(connections)
        require("dbee.loader").add_to_file(file)
      end,
      -- and this to remove them
      remove = function(connections)
        require("dbee.loader").remove_from_file(file)
      end,
    },
    -- ... the rest of your config
  }
  ```

#### Secrets

If you don't want to have secrets laying around your disk in plain text, you can
use the special placeholders in connection strings (this works using any method
for specifying connections).

NOTE: *Currently only envirnoment variables are supported*

Example:

Using the `DBEE_CONNECTIONS` environment variable for specifying connections and
exporting secrets to environment:

```sh
# Define connections
export DBEE_CONNECTIONS='[
    {
        "name": "{{ env.SECRET_DB_NAME }}",
        "url": "postgres://{{ env.SECRET_DB_USER }}:{{ env.SECRET_DB_PASS }}@localhost:5432/{{ env.SECRET_DB_NAME }}?sslmode=disable",
        "type": "postgres"
    }
]'

# Export secrets
export SECRET_DB_NAME="secretdb"
export SECRET_DB_USER="secretuser"
export SECRET_DB_PASS="secretpass"
```

If you start neovim in the same shell, this will evaluate to the following
connection:

```lua
{ {
  name = "secretdb",
  url = "postgres://secretuser:secretpass@localhost:5432/secretdb?sslmode=disable",
  type = "postgres",
} }
```

## Projector Integration

DBee is compatible with my other plugin
[nvim-projector](https://github.com/kndndrj/nvim-projector), a
code-runner/project-configurator.

To use dbee with it, simply use `"dbee"` as one of it's outputs.

<!-- DOCGEN_IGNORE_START -->

## Development

Reffer to [ARCHITECTURE.md](ARCHITECTURE.md) for a brief overview of the
architecture.

<!-- DOCGEN_IGNORE_END -->
