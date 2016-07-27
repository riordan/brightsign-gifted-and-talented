Sub CheckStorageDeviceIsWritable()

	' determine if the storage device is writable
	tmpFileName$ = "bs~69-96.txt"
	WriteAsciiFile(tmpFileName$, "1")
	readValue$ = ReadAsciiFile(tmpFileName$)
	if len(readValue$) = 1 and readValue$ = "1" then
		DeleteFile(tmpFileName$)
	else
		videoMode = CreateObject("roVideoMode")
		resX = videoMode.GetResX()
		resY = videoMode.GetResY()
		videoMode = invalid

		r = CreateObject("roRectangle", 0, 0, resX, resY)
		twParams = CreateObject("roAssociativeArray")
		twParams.LineCount = 1
		twParams.TextMode = 2
		twParams.Rotation = 0
		twParams.Alignment = 1
		tw=CreateObject("roTextWidget",r,1,2,twParams)
		tw.PushString("")
		tw.Show()

		r=CreateObject("roRectangle",0,resY/2-resY/32,resX,resY/32)
		tw=CreateObject("roTextWidget",r,1,2,twParams)
		tw.PushString("The attached storage device is write protected.")
		tw.Show()

		r2=CreateObject("roRectangle",0,resY/2,resX,resY/32)
		tw2=CreateObject("roTextWidget",r2,1,2,twParams)
		tw2.PushString("Remove it, enable writing, and reboot the device.")
		tw2.Show()

		msgPort = CreateObject("roMessagePort")
		msg = wait(0, msgPort)
	endif

End Sub


Sub CheckFirmwareVersion()

	modelObject = CreateObject("roDeviceInfo")

	' check to see whether or not the current firmware meets the minimum compatibility requirements
	versionNumber% = modelObject.GetVersionNumber()

	if modelObject.GetFamily() = "panther" then
		minVersionNumber% = 264058
		minVersion$ = "4.7.122"
	else if modelObject.GetFamily() = "cheetah" then
		minVersionNumber% = 264058
		minVersion$ = "4.7.122"
	else if modelObject.GetFamily() = "puma" then
		minVersionNumber% = 264058
		minVersion$ = "4.7.122"
	else
		minVersionNumber% = 199435
		minVersion$ = "3.11.11"
	endif

	if versionNumber% < minVersionNumber% then
		videoMode = CreateObject("roVideoMode")
		resX = videoMode.GetResX()
		resY = videoMode.GetResY()
		videoMode = invalid
		r=CreateObject("roRectangle",0,resY/2-resY/64,resX,resY/32)
		twParams = CreateObject("roAssociativeArray")
		twParams.LineCount = 1
		twParams.TextMode = 2
		twParams.Rotation = 0
		twParams.Alignment = 1
		tw=CreateObject("roTextWidget",r,1,2,twParams)
		tw.PushString("Firmware needs to be upgraded to " + minVersion$ + " or greater")
		tw.Show()
		msgPort = CreateObject("roMessagePort")
		gpioPort = CreateObject("roGpioControlPort")
		gpioPort.SetPort(msgPort)
		while true
			msg = wait(0, msgPort)
			if type(msg) = "roGpioButton" and msg.GetInt()=12 then
				stop
			endif
		end while
	endif
	
End Sub


Sub ClearRegistryKeys(registrySection As Object)

	' Clear legacy registry keys
	registrySection.Delete("next")
	registrySection.Delete("event")
	registrySection.Delete("error")
	registrySection.Delete("deviceerror")
	registrySection.Delete("devicedownload")
	registrySection.Delete("recurl")
	registrySection.Delete("timezone")
	registrySection.Delete("unitName")
	registrySection.Delete("unitNamingMethod")
	registrySection.Delete("unitDescription")
	registrySection.Delete("timeBetweenNetConnects")
	registrySection.Delete("contentDownloadsRestricted")
	registrySection.Delete("contentDownloadRangeStart")
	registrySection.Delete("contentDownloadRangeLength")
	registrySection.Delete("useDHCP")
	registrySection.Delete("staticIPAddress")
	registrySection.Delete("subnetMask")
	registrySection.Delete("gateway")
	registrySection.Delete("broadcast")
	registrySection.Delete("dns1")
	registrySection.Delete("dns2")
	registrySection.Delete("dns3")
	registrySection.Delete("timeServer")
	registrySection.Delete("account")
	registrySection.Delete("user")
	registrySection.Delete("password")
	registrySection.Delete("group")

	' Clear other keys in case they're no longer used
	registrySection.Delete("cdrs")
	registrySection.Delete("cdrl")
	registrySection.Delete("ps")
	registrySection.Delete("ss")
	registrySection.Delete("pp")
	registrySection.Delete("ncp2")
	registrySection.Delete("cwf")
	registrySection.Delete("twf")
	registrySection.Delete("hwf")
	registrySection.Delete("mwf")
	registrySection.Delete("lwf")
	registrySection.Delete("sip")
	registrySection.Delete("sip")
	registrySection.Delete("sm")
	registrySection.Delete("gw")
	registrySection.Delete("d1")
	registrySection.Delete("d2")
	registrySection.Delete("d3")
	registrySection.Delete("rlmow")
	registrySection.Delete("rlrow")
	registrySection.Delete("rlmiw")
	registrySection.Delete("rlriw")
	registrySection.Delete("rlmid")
	registrySection.Delete("rlrid")
	registrySection.Delete("sip2")
	registrySection.Delete("sm2")
	registrySection.Delete("gw2")
	registrySection.Delete("d12")
	registrySection.Delete("d22")
	registrySection.Delete("d32")
	registrySection.Delete("rlmow2")
	registrySection.Delete("rlrow2")
	registrySection.Delete("rlmiw2")
	registrySection.Delete("rlriw2")
	registrySection.Delete("rlmid2")
	registrySection.Delete("rlrid2")
	registrySection.Delete("uup")
	registrySection.Delete("cfv")

End Sub


Function GetRateLimits(current_sync As Object, rateLimitModeKey$ As String, rateLimitRateKey$ As String)

	rateLimitModeSpec$ = GetEntry(current_sync, rateLimitModeKey$)

	rateLimitMode$ = "default"
	rateLimitRate$ = "0"
	rateLimitRate% = -1

	if rateLimitModeSpec$ = "unlimited" then
		rateLimitMode$ = "unlimited"
		rateLimitRate% = 0
	else if rateLimitModeSpec$ = "specified" then
		rateLimitMode$ = "specified"
		rateLimitRate$ = GetEntry(current_sync, rateLimitRateKey$)
		rateLimitRate% = int(val(rateLimitRate$))
	endif

	rateLimits = { }
	rateLimits.rateLimitMode$ = rateLimitMode$
	rateLimits.rateLimitRate$ = rateLimitRate$
	rateLimits.rateLimitRate% = rateLimitRate%

	return rateLimits

End Function


Function SetNetworkConfiguration(current_sync As Object, registrySection As Object, keySuffix$ As String, registrySuffix$ As String)

	networkingParameters = { }

	networkingParameters.useDHCP$ = GetEntry(current_sync, "useDHCP" + keySuffix$)
	if networkingParameters.useDHCP$ = "no" then
		networkingParameters.staticIPAddress$ = GetEntry(current_sync, "staticIPAddress" + keySuffix$)
		networkingParameters.subnetMask$ = GetEntry(current_sync, "subnetMask" + keySuffix$)
		networkingParameters.gateway$ = GetEntry(current_sync, "gateway" + keySuffix$)
		networkingParameters.dns1$ = GetEntry(current_sync, "dns1" + keySuffix$)
		networkingParameters.dns2$ = GetEntry(current_sync, "dns2" + keySuffix$)
		networkingParameters.dns3$ = GetEntry(current_sync, "dns3" + keySuffix$)

		registrySection.Write("dhcp" + registrySuffix$, "no")
		registrySection.Write("sip" + registrySuffix$, networkingParameters.staticIPAddress$)
		registrySection.Write("sm" + registrySuffix$, networkingParameters.subnetMask$)
		registrySection.Write("gw" + registrySuffix$, networkingParameters.gateway$)
		registrySection.Write("d1" + registrySuffix$, networkingParameters.dns1$)
		registrySection.Write("d2" + registrySuffix$, networkingParameters.dns2$)
		registrySection.Write("d3" + registrySuffix$, networkingParameters.dns3$)
	else
		registrySection.Write("dhcp" + registrySuffix$, "yes")
	endif

	rateLimits = GetRateLimits(current_sync, "rateLimitModeOutsideWindow" + keySuffix$, "rateLimitRateOutsideWindow" + keySuffix$)
	rlmow$ = rateLimits.rateLimitMode$
	rlrow$ = rateLimits.rateLimitRate$

	rateLimits = GetRateLimits(current_sync, "rateLimitModeInWindow" + keySuffix$, "rateLimitRateInWindow" + keySuffix$)
	rlmiw$ = rateLimits.rateLimitMode$
	rlriw$ = rateLimits.rateLimitRate$

	rateLimits = GetRateLimits(current_sync, "rateLimitModeInitialDownloads" + keySuffix$, "rateLimitRateInitialDownloads" + keySuffix$)
	rlmid$ = rateLimits.rateLimitMode$
	rlrid$ = rateLimits.rateLimitRate$
	networkingParameters.rl% = rateLimits.rateLimitRate%

	registrySection.Write("rlmow" + registrySuffix$, rlmow$)
	registrySection.Write("rlrow" + registrySuffix$, rlrow$)
	registrySection.Write("rlmiw" + registrySuffix$, rlmiw$)
	registrySection.Write("rlriw" + registrySuffix$, rlriw$)
	registrySection.Write("rlmid" + registrySuffix$, rlmid$)
	registrySection.Write("rlrid" + registrySuffix$, rlrid$)

	return networkingParameters

End Function


Function SetLogging(spec As Object, registrySection As Object) As Object

	logging = { } 

    logging.diagnosticLoggingEnabled = false
    logging.uploadLogFilesAtBoot = false
    logging.uploadLogFilesAtSpecificTime = false
    logging.uploadLogFilesTime% = 0

    b$ = LCase(GetEntry(spec, "playbackLoggingEnabled"))
    logging.playbackLoggingEnabled$ = "no"
    if b$ = "yes" then logging.playbackLoggingEnabled$ = "yes"

    b$ = LCase(GetEntry(spec, "eventLoggingEnabled"))
    logging.eventLoggingEnabled$ = "no"
    if b$ = "yes" then logging.eventLoggingEnabled$ = "yes"

    b$ = LCase(GetEntry(spec, "stateLoggingEnabled"))
    logging.stateLoggingEnabled$ = "no"
    if b$ = "yes" then logging.stateLoggingEnabled$ = "yes"

    b$ = LCase(GetEntry(spec, "diagnosticLoggingEnabled"))
    logging.diagnosticLoggingEnabled$ = "no"
    if b$ = "yes" then
		logging.diagnosticLoggingEnabled$ = "yes"
		logging.diagnosticLoggingEnabled = true
	endif

    b$ = LCase(GetEntry(spec, "uploadLogFilesAtBoot"))
    logging.uploadLogFilesAtBoot$ = "no"
    if b$ = "yes" then
		logging.uploadLogFilesAtBoot$ = "yes"
        logging.uploadLogFilesAtBoot = true
	endif

    b$ = LCase(GetEntry(spec, "uploadLogFilesAtSpecificTime"))
    logging.uploadLogFilesAtSpecificTime$ = "no"
    if b$ = "yes" then
		logging.uploadLogFilesAtSpecificTime$ = "yes"
		logging.uploadLogFilesAtSpecificTime = true
	endif

    logging.uploadLogFilesTime$ = GetEntry(spec, "uploadLogFilesTime")
    if logging.uploadLogFilesTime$ <> "" then logging.uploadLogFilesTime% = int(val(logging.uploadLogFilesTime$))

	if type(registrySection) = "roRegistrySection" then
		registrySection.Write("ple", logging.playbackLoggingEnabled$)
		registrySection.Write("ele", logging.eventLoggingEnabled$)
		registrySection.Write("sle", logging.stateLoggingEnabled$)
		registrySection.Write("dle", logging.diagnosticLoggingEnabled$)
		registrySection.Write("uab", logging.uploadLogFilesAtBoot$)
		registrySection.Write("uat", logging.uploadLogFilesAtSpecificTime$)
		registrySection.Write("ut", logging.uploadLogFilesTime$)
	endif

	return logging

End Function


Function GetEntry(spec As Object, key$ As String) As String

	if type(spec) = "roSyncSpec" then
		return spec.LookupMetadata("client", key$)
	else
		ele = spec.GetNamedElements(key$)
		if type(ele) <> "roXMLList" then
			return ""
		endif
		if ele.Count() <> 1 then
			return ""
		endif
    
		return ele.GetText()    
	endif

End Function


Function GetModelSupportsWifi()

    modelSupportsWifi = false
    nc = CreateObject("roNetworkConfiguration", 1)
    if type(nc) = "roNetworkConfiguration" then
        currentConfig = nc.GetCurrentConfig()
        if type(currentConfig) = "roAssociativeArray" then
            modelSupportsWifi = true
        endif
    endif
    nc = invalid
	return modelSupportsWifi

End Function


Sub SetLWS(spec As Object, registrySection As Object)

	' delete obsolete lws keys    
	registrySection.Delete("lws")
	registrySection.Delete("lwsu")
	registrySection.Delete("lwsp")

    ' local web server
    lwsConfig$ = GetEntry(spec, "lwsConfig")
    lwsUserName$ = GetEntry(spec, "lwsUserName")
    lwsPassword$ = GetEntry(spec, "lwsPassword")
	lwsEnableUpdateNotifications$ = GetEntry(spec, "lwsEnableUpdateNotifications")
	if lwsEnableUpdateNotifications$ = "" then
		lwsEnableUpdateNotifications$ = "yes"
	endif

    if lwsConfig$ = "content" or lwsConfig$ = "status" then
        registrySection.Write("nlws", Left(lwsConfig$, 1))
        registrySection.Write("nlwsu", lwsUserName$)
        registrySection.Write("nlwsp", lwsPassword$)
		registrySection.Write("nlwseun", lwsEnableUpdateNotifications$)
    else
        registrySection.Delete("nlws")
        registrySection.Delete("nlwsu")
        registrySection.Delete("nlwsp")
		registrySection.Delete("nlwseun")
    endif

End Sub


Sub SetHostname(spec As Object)

	specifyHostname$ = GetEntry(spec, "specifyHostname")
	if specifyHostname$ = "yes" then
		hostname$ = GetEntry(spec, "hostname")
	
		nc = CreateObject("roNetworkConfiguration", 0)

		if type(nc) <> "roNetworkConfiguration" then
			nc = CreateObject("roNetworkConfiguration", 1)
		endif

		if type(nc) = "roNetworkConfiguration" then
			ok = nc.SetHostname(hostname$)
			if ok nc.Apply()
			nc = invalid
		endif
	endif

End Sub


Sub SetDWS(spec As Object, registrySection As Object)

	' diagnostic web server
	dwsEnabled$ = GetEntry(spec, "dwsEnabled")
	dwsPassword$ = GetEntry(spec, "dwsPassword")

	dwsAA = CreateObject("roAssociativeArray")
	if dwsEnabled$ = "yes" then
		dwsAA["port"] = "80"
		dwsAA["password"] = dwsPassword$
	else
		dwsAA["port"] = 0
	endif

	registrySection.Write("dwse", dwsEnabled$)
	registrySection.Write("dwsp", dwsPassword$)

	' set DWS on device
	nc = CreateObject("roNetworkConfiguration", 0)

	if type(nc) <> "roNetworkConfiguration" then
		nc = CreateObject("roNetworkConfiguration", 1)
	endif

	if type(nc) = "roNetworkConfiguration" then
		rebootRequired = nc.SetupDWS(dwsAA)
	endif

End Sub


Sub ConfigureEthernet(ethernetNetworkingParameters As Object, networkConnectionPriorityWired$ As String, timeServer$ As String, proxySpec$ As String)
	nc = CreateObject("roNetworkConfiguration", 0)
	if type(nc) = "roNetworkConfiguration" then
		ConfigureNetwork(nc, ethernetNetworkingParameters, networkConnectionPriorityWired$, timeServer$, proxySpec$)
	else
		print "Unable to create roNetworkConfiguration - index = 0"
	endif
End Sub


Sub ConfigureWifi(wifiNetworkingParameters As Object, ssid$ As String, passphrase$ As String, networkConnectionPriorityWireless$ As String, timeServer$ As String, proxySpec$ As String)
	nc = CreateObject("roNetworkConfiguration", 1)
	if type(nc) = "roNetworkConfiguration" then
		nc.SetWiFiESSID(ssid$)
		nc.SetObfuscatedWifiPassphrase(passphrase$)
		ConfigureNetwork(nc, wifiNetworkingParameters, networkConnectionPriorityWireless$, timeServer$, proxySpec$)
	else
		print "Unable to create roNetworkConfiguration - index = 1"
	endif
End Sub


Sub ConfigureNetwork(nc As Object, networkingParameters As Object, networkConnectionPriority$ As String, timeServer$ As String, proxySpec$ As String)

	if networkingParameters.useDHCP$ = "no" then
		nc.SetIP4Address(networkingParameters.staticIPAddress$)
		nc.SetIP4Netmask(networkingParameters.subnetMask$)
		nc.SetIP4Gateway(networkingParameters.gateway$)
		if networkingParameters.dns1$ <> "" then nc.AddDNSServer(networkingParameters.dns1$)
		if networkingParameters.dns2$ <> "" then nc.AddDNSServer(networkingParameters.dns2$)
		if networkingParameters.dns3$ <> "" then nc.AddDNSServer(networkingParameters.dns3$)
	else
		nc.SetDHCP()
	endif

	nc.SetRoutingMetric(int(val(networkConnectionPriority$)))
	nc.SetTimeServer(timeServer$)
	nc.SetProxy(proxySpec$)
	nc.SetInboundShaperRate(networkingParameters.rl%)
	success = nc.Apply()

End Sub


Sub DisableWireless()
	nc = CreateObject("roNetworkConfiguration", 1)
	if type(nc) = "roNetworkConfiguration" then
		nc.SetDHCP()
		nc.SetWiFiESSID("")
		nc.SetObfuscatedWifiPassphrase("")
		nc.Apply()
	endif
End Sub


Sub SetWiredParameters(spec As Object, registrySection As Object, useWireless$ As String)

	if useWireless$ = "yes" then
		registrySection.Write("ncp", GetEntry(spec, "networkConnectionPriorityWired"))
		registrySection.Write("cwr", GetEntry(spec, "contentDataTypeEnabledWired"))
		registrySection.Write("twr", GetEntry(spec, "textFeedsDataTypeEnabledWired"))
		registrySection.Write("hwr", GetEntry(spec, "healthDataTypeEnabledWired"))
		registrySection.Write("mwr", GetEntry(spec, "mediaFeedsDataTypeEnabledWired"))
		registrySection.Write("lwr", GetEntry(spec, "logUploadsDataTypeEnabledWired"))
	else
		registrySection.Write("ncp", "0")
		registrySection.Write("cwr", "True")
		registrySection.Write("twr", "True")
		registrySection.Write("hwr", "True")
		registrySection.Write("mwr", "True")
		registrySection.Write("lwr", "True")
	endif

End Sub


Function SetWirelessParameters(spec As Object, registrySection As Object, modelSupportsWifi As Boolean) As String

	useWireless = GetEntry(spec, "useWireless")

	' if the user specifies wireless on a system that doesn't support wireless, don't try to use wireless
	if not modelSupportsWifi
		useWireless = "no"
	endif

	if useWireless = "yes" then
		ssid$ = GetEntry(spec, "ssid")
		passphrase$ = GetEntry(spec, "passphrase")
		registrySection.Write("wifi", "yes")
		registrySection.Write("ss", ssid$)
		registrySection.Write("pp", passphrase$)

		registrySection.Write("ncp2", GetEntry(spec, "networkConnectionPriorityWireless"))
		registrySection.Write("cwf", GetEntry(spec, "contentDataTypeEnabledWireless"))
		registrySection.Write("twf", GetEntry(spec, "textFeedsDataTypeEnabledWireless"))
		registrySection.Write("hwf", GetEntry(spec, "healthDataTypeEnabledWireless"))
		registrySection.Write("mwf", GetEntry(spec, "mediaFeedsDataTypeEnabledWireless"))
		registrySection.Write("lwf", GetEntry(spec, "logUploadsDataTypeEnabledWireless"))
	else
		registrySection.Write("wifi", "no")        
	endif

	return useWireless

End Function


Function GetProxy(spec As Object, registrySection As Object) As String

	useProxy = false
	useProxy$ = GetEntry(spec, "useProxy")
	proxySpec$ = ""
	if lcase(useProxy$) = "yes" then
		useProxy = true
		proxySpec$ = GetEntry(spec, "proxy")

		registrySection.Write("up", "yes")
		registrySection.Write("ps", proxySpec$)
	else
		registrySection.Write("up", "no")
	endif

	return proxySpec$

End Function


Function GetDataTransferEnabled(spec$ As String) As Boolean

	dataTransferEnabled = true
	if lcase(spec$) = "false" then dataTransferEnabled = false
	return dataTransferEnabled

End Function


Function GetBinding(wiredTransferEnabled As Boolean, wirelessTransferEnabled As Boolean) As Integer

	binding% = -1
	if wiredTransferEnabled <> wirelessTransferEnabled then
		if wiredTransferEnabled then
			binding% = 0
		else
			binding% = 1
		endif
	endif

	return binding%

End Function


Function GetModelSupportsTuner() As Boolean

    modelSupportsTuner = false

	modelObject = CreateObject("roDeviceInfo")
	if modelObject.GetModel() = "XD1230" return true

	return false

End Function


Sub SetupTunerData()

	if GetModelSupportsTuner() then
		tunerData$ = ReadAsciiFile("ScannedChannelsForSetup.xml")
		if tunerData$ <> "" then
			cdataStartTag$ = "<![CDATA["
			cdataEndTag$ = " ]]>"
			docEndTag$ = "</BrightSignRFChannels>"
			cdataIndex% = instr(1, tunerData$, cdataStartTag$)
			if cdataIndex% > 0 then
				fwXML$ = mid(tunerData$, cdataIndex% + len(cdataStartTag$) + 1, len(tunerData$) - (cdataIndex% + len(cdataStartTag$) + 1) - (len(cdataEndTag$) + len(docEndTag$) + 1))
				channelManager = CreateObject("roChannelManager")
				ok = channelManager.ImportFromXml(fwXML$)
			endif
		endif
	endif

End Sub


Function GetBooleanSyncSpecEntry(syncSpec As Object, metadataField$ As String) As Boolean
	
	metadata$ = syncSpec.LookupMetadata("client", metadataField$)
	if lcase(metadata$) = "true" then
		return true
	else
		return false
	endif

End Function


Sub SetIdleColor(spec As Object, registrySection As Object)

	idleScreenColor$ = GetEntry(spec, "idleScreenColor")
	registrySection.Write("isc", idleScreenColor$)

End Sub

