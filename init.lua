local framework = require('framework')
local net = require('net')
local table = require('table')
local json = require('json')
local os = require('os')
local Plugin = framework.Plugin
local DataSourcePoller = framework.DataSourcePoller
local PollerCollection = framework.PollerCollection
local notEmpty = framework.string.notEmpty
local params = framework.params
local parseJson = framework.util.parseJson
--local logger = framework.Logger
local DataSource= framework.DataSource
local ProcessCpuDataSource = framework.ProcessCpuDataSource
params.items = params.items or {}


--[[
-- For compatability with lua versions prior to 4.1.2
if framework.plugin_params.name == nil then
  params.name = 'Boundary Demo Plugin'
  params.version = '1.0'
  params.tags = 'applicationA'
end
params.minValue = params.minValue or 1
params.maxValue = params.maxValue or 100

local data_source = RandomDataSource:new(params.minValue, params.maxValue)
local plugin = Plugin:new(params, data_source)
]]--
--[[local data_source = MeterDataSource:new()
function data_source:onFetch(socket)
  socket:write(self:queryMetricCommand({match = 'system.cpu.usage'}))
end
]]--
--vitiwari
local function poller(item)
 local options = {}

   options.process = item.processName or ''
   options.path_expr = item.processPath or ''
   options.cwd_expr = item.processCwd or ''
   options.args_expr = item.processArgs or ''
   options.reconcile = item.reconcile or ''
   item.pollInterval = notEmpty(item.pollInterval,1000)
   local ds =  	ProcessCpuDataSource:new(options)
  local p = DataSourcePoller:new(item.pollInterval, ds)
  return p 
end


local function createPollers(items)
  local pollers = PollerCollection:new() 
  for _, i in pairs(items) do
    pollers:add(poller(i))
  end
  return pollers
end

local pollers = createPollers(params.items)
local plugin = Plugin:new({pollInterval = 1000}, pollers)


function plugin:onParseValues(data,extra)
    local result = {}
    for K,V  in pairs(data) do
       --print("--FFFFFFFFFFFF----> K:V::",K,json.stringify(V))
       result['PROCESS_CPU_PERCENTAGE'] = V
       --for ki,vi in pairs(V) do
        -- print("FFFFFFFFFFFFFF  ki::vi::::",ki,vi)
      --end
    end
    
    return result 
end

function plugin:onError(err)
  if err.context then
    err.source = err.context.info.source
    err.message = err.message and err.message .. ' for ' .. err.context.options.href   
  end
  result = {}
  self:report(result)
  return err  
end

plugin:run()

