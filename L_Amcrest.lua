--[==[
_NAME = "Amcrest"
_VERSION = "0.2"
_DESCRIPTION = "Amcrest plugin"
_AUTHOR = "rafale77"
--]==]

local is_LuaJIT = ({false, [1] = true})[1]
local CAM_SID = "urn:micasaverde-com:serviceId:Camera1"
local HAD_SID = "urn:micasaverde-com:serviceId:HaDevice1"
local SES_SID = "urn:micasaverde-com:serviceId:SecuritySensor1"
if is_LuaJIT then
  http = require("luajit-request")
else
  http = require("http-digest")
end

local function digest(url)
  local response = http.request(url, {
    auth_type = "digest",
	  username = luup.devices[lul_device].user,
	  password = luup.devices[lul_device].pass
   })
  return response
end

function getSetVariable(serviceId, name, deviceId, default)
  local curValue = luup.variable_get(serviceId, name, deviceId)
  if (curValue == nil) then
    curValue = default
    luup.variable_set(serviceId, name, curValue, deviceId)
  end
  return curValue
end

function cmdsend(code, func, arg)
  local url = "http://" ..luup.devices[lul_device].ip.. "/cgi-bin/" ..func.. ".cgi?action=start&channel=0&code=".. code .. "&arg1=0&arg2=" .. arg .. "&arg3=0"
  digest(url)
  --luup.inet.wget(url)
end

function snapcmd()
  url = "http://" ..luup.devices[lul_device].ip.. "/cgi-bin/snapshot.cgi"
  digest(url)
end

function stopPanTiltZoom()
  local url = "http://" ..luup.devices[lul_device].ip.. "/cgi-bin/ptz.cgi?action=stop&channel=0&code=Up&arg1=0&arg2=0&arg3=0"
  digest(url)
end

--Enable motion and audio detect (true/false)
function DetectionEnable(action)
  url = "http://" ..luup.devices[lul_device].ip.. "/cgi-bin/configManager.cgi?action=setConfig&amp;MotionDetect[0].Enable=" .. action
  digest(url)
  url = "http://" ..luup.devices[lul_device].ip.. "/cgi-bin/configManager.cgi?action=setConfig&amp;AudioDetect[0].AnomalyDetect.Enable=" .. action .. "&amp;AudioDetect[0].MutationDetect=" .. action
  digest(url)
end

function init(lul_device)

  luup_devices = lul_device
  luup.set_failure(false)

-- Check if we have the correct category number.
  if (luup.devices[lul_device].category_num ~= 6) then
    luup.attr_set("category_num", "6", lul_device)
  end

-- Get username, password and IP
  luup.devices[lul_device].user = getSetVariable(CAM_SID, "Username", lul_device, "Set your cam user here")
  luup.devices[lul_device].pass = getSetVariable(CAM_SID, "Password", lul_device, "Set your cam password here")
-- Set default snapshot URL
  if not luup.variable_get(CAM_SID, "URL", lul_device) then
	  luup.variable_set(CAM_SID, "URL", "/cgi-bin/snapshot.cgi", lul_device)
  end
-- Set Direct Streaming URL for ALTUI
  if not luup.variable_get(CAM_SID, "DirectStreamingURL", lul_device) then
    luup.variable_set(CAM_SID, "DirectStreamingURL","/cgi-bin/mjpg/video.cgi?[channel=1]&subtype=1", lul_device)
  end


-- Set supported camera features (pan/tilt/zoom/presets) and update the 'Commands' variable with the available commands.
  local commands = "camera_full_screen,camera_left,camera_right,camera_up,camera_down,camera_preset,camera_zoom_in,camera_zoom_out"

  luup.variable_set("urn:micasaverde-com:serviceId:HaDevice1", "Commands", commands, lul_device)

  local stepSize = luup.variable_get(CAM_SID, "StepSize", lul_device) or ""
  if (stepSize == "") then
    stepSize = "1"
    luup.variable_set(CAM_SID, "StepSize", stepSize, lul_device)
  end

    local reverseControls = luup.variable_get(CAM_SID, "ReverseControls", lul_device) or ""
    if (reverseControls == "") then
      reverseControls = "0"
      luup.variable_set(CAM_SID, "ReverseControls", reverseControls, lul_device)
    end
end
