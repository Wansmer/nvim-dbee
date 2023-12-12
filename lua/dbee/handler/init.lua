local event_bus = require("dbee.handler.__events")

-- Helpers
---@alias materialization "table"|"view"
---@alias helper_opts { table: string, schema: string, materialization: materialization}
---@alias table_helpers table<string, string>

-- Call (single call to database)
---@alias duration integer duration (time period) in microseconds
---@alias timestamp integer time in microseconds
---@alias call_stats { success: boolean, time_taken: duration }
---@alias call_id string
---@alias call_state "unknown"|"executing"|"executing_failed"|"retrieving"|"retrieving_failed"|"archived"|"archive_failed"|"canceled"
---@alias call_details { id: call_id, time_taken_us: duration, query: string, state: call_state, timestamp_us: timestamp }

-- Connection
---@alias conn_id string
---@alias connection_details { name: string, type: string, url: string, id: conn_id }

-- Structure of database
---@class DBStructure
---@field name string display name
---@field type ""|"table"|"history"|"database_switch"|"view" type of layout -> this infers action
---@field schema? string parent schema
---@field children? DBStructure[] child layout nodes

-- Handler is an aggregator of connections
---@class Handler
---@field private sources table<source_id, Source>
---@field private source_conn_lookup table<string, conn_id[]>
local Handler = {}

---@param sources? Source[]
---@return Handler
function Handler:new(sources)
  -- class object
  local o = {
    sources = {},
    source_conn_lookup = {},
  }
  setmetatable(o, self)
  self.__index = self

  -- initialize the sources
  sources = sources or {}
  for _, source in ipairs(sources) do
    pcall(o.add_source, o, source)
  end

  return o
end

---@param event handler_event_name
---@param listener handler_event_listener
function Handler:register_event_listener(event, listener)
  event_bus.register(event, listener)
end

-- add new source and load connections from it
---@param source Source
function Handler:add_source(source)
  local id = source:name()

  -- keep the old source if present
  self.sources[id] = self.sources[id] or source

  self:source_reload(id)
end

---@return Source[]
function Handler:get_sources()
  local sources = vim.tbl_values(self.sources)
  table.sort(sources, function(k1, k2)
    return k1:name() < k2:name()
  end)
  return sources
end

---@param id source_id
function Handler:source_reload(id)
  local source = self.sources[id]
  if not source then
    return
  end

  -- add new connections
  self.source_conn_lookup[id] = {}
  for _, spec in ipairs(source:load()) do
    spec.id = spec.id or spec.type .. spec.name

    local conn_id = vim.fn.DbeeCreateConnection(spec)
    table.insert(self.source_conn_lookup[id], conn_id)
  end
end

---@param id source_id
---@param details connection_details[]
function Handler:source_add_connections(id, details)
  if not details then
    return
  end

  local source = self.sources[id]
  if not source then
    return
  end

  if type(source.save) == "function" then
    source:save(details, "add")
  end

  self:source_reload(id)
end

---@param id source_id
---@param details connection_details[]
function Handler:source_remove_connections(id, details)
  if not details then
    return
  end

  local source = self.sources[id]
  if not source then
    return
  end

  if type(source.save) == "function" then
    source:save(details, "delete")
  end

  self:source_reload(id)
end

---@param id source_id
---@return connection_details[]
function Handler:source_get_connections(id)
  local conn_ids = self.source_conn_lookup[id] or {}
  if #conn_ids < 1 then
    return {}
  end

  ---@type connection_details[]?
  local ret = vim.fn.DbeeGetConnections { ids = conn_ids }
  if not ret or ret == vim.NIL then
    return {}
  end

  table.sort(ret, function(k1, k2)
    return k1.name < k2.name
  end)

  return ret
end

---@param helpers table<string, table_helpers> extra helpers per type
function Handler:add_helpers(helpers)
  for type, help in pairs(helpers) do
    vim.fn.DbeeAddHelpers { type = type, helpers = help }
  end
end

---@param id conn_id
---@param opts helper_opts
---@return table_helpers helpers list of table helpers
function Handler:connection_get_helpers(id, opts)
  local helpers = vim.fn.DbeeConnectionGetHelpers {
    id = id,
    table = opts.table,
    schema = opts.schema,
    materialization = opts.materialization,
  }
  if not helpers or helpers == vim.NIL then
    return {}
  end

  return helpers
end

---@return connection_details?
function Handler:get_current_connection()
  local ret = vim.fn.DbeeGetCurrentConnection()
  if ret == vim.NIL then
    return
  end
  return ret
end

---@param id conn_id
function Handler:set_current_connection(id)
  vim.fn.DbeeSetCurrentConnection { id = id }
end

---@param id conn_id
---@param query string
---@return call_details
function Handler:connection_execute(id, query)
  return vim.fn.DbeeConnectionExecute { id = id, query = query }
end

---@param id conn_id
---@return DBStructure[]
function Handler:connection_get_structure(id)
  local ret = vim.fn.DbeeConnectionGetStructure { id = id }
  if not ret or ret == vim.NIL then
    return {}
  end
  return ret
end

---@param id conn_id
---@return connection_details?
function Handler:connection_get_params(id)
  local ret = vim.fn.DbeeConnectionGetParams { id = id }
  if not ret or ret == vim.NIL then
    return
  end
  return ret
end

---@param id conn_id
---@return string current_db
---@return string[] available_dbs
function Handler:connection_list_databases(id)
  local ret = vim.fn.DbeeConnectionListDatabases { id = id }
  if not ret or ret == vim.NIL then
    return "", {}
  end

  return unpack(ret)
end

---@param id conn_id
---@param database string
function Handler:connection_select_database(id, database)
  vim.fn.DbeeConnectionSelectDatabase { id = id, database = database }
end

---@param id conn_id
---@return call_details[]
function Handler:connection_get_calls(id)
  local ret = vim.fn.DbeeConnectionGetCalls { id = id }
  if not ret or ret == vim.NIL then
    return {}
  end
  return ret
end

---@param id call_id
function Handler:call_cancel(id)
  vim.fn.DbeeCallCancel { id = id }
end

---@param id call_id
---@param bufnr integer
---@param from integer
---@param to integer
---@return integer # total number of rows
function Handler:call_display_result(id, bufnr, from, to)
  local length = vim.fn.DbeeCallDisplayResult { id = id, buffer = bufnr, from = from, to = to }
  if not length or length == vim.NIL then
    return 0
  end
  return length
end

---@param id call_id
---@param format "csv"|"json"|"table" format of the output
---@param output "file"|"yank"|"buffer" where to pipe the results
---@param opts { from: integer, to: integer, extra_arg: any }
function Handler:call_store_result(id, format, output, opts)
  opts = opts or {}

  local from = opts.from or 0
  local to = opts.to or -1

  local path
  if output == "file" then
    path = opts.extra_arg
  end
  local bufnr
  if output == "buffer" then
    bufnr = opts.extra_arg
  end
  local register
  if output == "yank" then
    register = opts.extra_arg
  end

  vim.fn.DbeeCallStoreResult {
    id = id,
    format = format,
    output = output,
    from = from,
    to = to,

    path = path,
    bufnr = bufnr,
    register = register,
  }
end

return Handler
