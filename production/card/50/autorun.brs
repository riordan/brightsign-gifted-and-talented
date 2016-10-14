Library "setupCommon.brs"
Library "setupNetworkDiagnostics.brs"

REM
REM autorun-setup - setup file for simple networking
REM Copyright (c) 2006-2013 BrightSign, LLC.
REM 

Sub Main()

    setupVersion$ = "3.7.0.1"
    print "setup script version ";setupVersion$;" started"

	CheckFirmwareVersion()

	CheckStorageDeviceIsWritable()

    debugOn = true
    loggingOn = false
    
    diagnosticCodes = newDiagnosticCodes()

    RunSetup(setupVersion$, debugOn, loggingOn, diagnosticCodes)

    Stop
    
End Sub


Sub RunSetup(setupVersion$ As String, debugOn As Boolean, loggingOn As Boolean, diagnosticCodes As Object)

    Setup = newSetup(debugOn, loggingOn)

	modelObject = CreateObject("roDeviceInfo")
    sysInfo = CreateObject("roAssociativeArray")
    sysInfo.deviceUniqueID$ = modelObject.GetDeviceUniqueId()
    sysInfo.deviceFWVersion$ = modelObject.GetVersion()
    sysInfo.deviceModel$ = modelObject.GetModel()
    sysInfo.deviceFamily$ = modelObject.GetFamily()
    sysInfo.setupVersion$ = setupVersion$
    sysInfo.deviceFWVersionNumber% = modelObject.GetVersionNumber()

    ' create pool directory
    ok = CreateDirectory("pool")

    Setup.SetSystemInfo(sysInfo, diagnosticCodes)

	currentSync = CreateObject("roSyncSpec")
	if not currentSync.ReadFromFile("current-sync.xml") then
	    Setup.diagnostics.PrintDebug("### No current sync state available")
		stop
	endif

' initialize logging parameters
	loggingParameters = SetLogging(currentSync, invalid)

' initialize networking
    Setup.networkingActive = Setup.networking.InitializeNetworkDownloads(loggingParameters.playbackLoggingEnabled$, loggingParameters.eventLoggingEnabled$, loggingParameters.stateLoggingEnabled$, loggingParameters.diagnosticLoggingEnabled$, loggingParameters.variableLoggingEnabled$, loggingParameters.uploadLogFilesAtBoot$, loggingParameters.uploadLogFilesAtSpecificTime$, loggingParameters.uploadLogFilesTime$)

' setup logging
    Setup.logging.InitializeLogging(false, false, false, loggingParameters.diagnosticLoggingEnabled, loggingParameters.variableLoggingEnabled, loggingParameters.uploadLogFilesAtBoot, loggingParameters.uploadLogFilesAtSpecificTime, loggingParameters.uploadLogFilesTime%)
    
    Setup.logging.WriteDiagnosticLogEntry(diagnosticCodes.EVENT_STARTUP, sysInfo.deviceFWVersion$ + chr(9) + sysInfo.setupVersion$ + chr(9) + "")

    Setup.EventLoop()
    
    return

End Sub


Function newSetup(debugOn As Boolean, loggingOn As Boolean) As Object

    Setup = CreateObject("roAssociativeArray")

    Setup.debugOn = debugOn
    
    Setup.systemTime = CreateObject("roSystemTime")
    Setup.diagnostics = newDiagnostics(debugOn, loggingOn)

    Setup.msgPort = CreateObject("roMessagePort")

    Setup.newLogging = newLogging
    Setup.logging = Setup.newLogging()
    Setup.newNetworking = newNetworking
    Setup.networking = Setup.newNetworking(Setup)    
    Setup.logging.networking = Setup.networking
        
    Setup.SetSystemInfo = SetupSetSystemInfo
    Setup.EventLoop = EventLoop

    return Setup

End Function
 

Sub SetupSetSystemInfo(sysInfo As Object, diagnosticCodes As Object)

    m.diagnostics.SetSystemInfo(sysInfo, diagnosticCodes)
    m.networking.SetSystemInfo(sysInfo, diagnosticCodes)
    m.logging.SetSystemInfo(sysInfo, diagnosticCodes)
    
End Sub


Sub EventLoop()

    while true
    
	    msg = wait(0, m.msgPort)
	    
	    if (type(msg) = "roUrlEvent") then
	    
            m.networking.URLEvent(msg)
		    
	    elseif (type(msg) = "roSyncPoolEvent") then
	    
            m.networking.PoolEvent(msg)
		    
	    elseif (type(msg) = "roTimerEvent") then
	    
            ' see if the timer is for Logging
            loggingTimeout = false
            if type(m.logging) = "roAssociativeArray" then
                if type(m.logging.cutoverTimer) = "roTimer" then
                    if msg.GetSourceIdentity() = m.logging.cutoverTimer.GetIdentity() then
                        ' indicate that event was for logging
                        m.logging.HandleTimerEvent(msg)
                        loggingTimeout = true
                    endif
                endif
            endif

            if not loggingTimeout then
    		    m.networking.StartSync()
	        endif
	
	    elseif (type(msg) = "roSyncPoolProgressEvent") then
	    
	        m.networking.SyncPoolProgressEvent(msg)
	        
	    endif

    endwhile

    return

End Sub


REM *******************************************************
REM *******************************************************
REM ***************                    ********************
REM *************** DIAGNOSTICS OBJECT ********************
REM ***************                    ********************
REM *******************************************************
REM *******************************************************

REM
REM construct a new diagnostics BrightScript object
REM
Function newDiagnostics(debugOn As Boolean, loggingOn As Boolean) As Object

    diagnostics = CreateObject("roAssociativeArray")
    
    diagnostics.debug = debugOn
    diagnostics.logging = loggingOn
    diagnostics.setupVersion$ = "unknown"
    diagnostics.deviceFWVersion$ = "unknown"
    diagnostics.systemTime = CreateObject("roSystemTime")
    
    diagnostics.PrintDebug = PrintDebug
    diagnostics.PrintTimestamp = PrintTimestamp
    diagnostics.OpenLogFile = OpenLogFile
    diagnostics.CloseLogFile = CloseLogFile
    diagnostics.OldFlushLogFile = OldFlushLogFile
    diagnostics.WriteToLog = WriteToLog
    diagnostics.SetSystemInfo = SetSystemInfo
    diagnostics.RotateLogFiles = RotateLogFiles
    diagnostics.TurnDebugOn = TurnDebugOn
    
    diagnostics.OpenLogFile()

    return diagnostics

End Function


Sub TurnDebugOn()

    m.debug = true
    
    return
    
End Sub


Sub SetSystemInfo(sysInfo As Object, diagnosticCodes As Object)

    m.setupVersion$ = sysInfo.setupVersion$
    m.deviceFWVersion$ = sysInfo.deviceFWVersion$
    m.deviceUniqueID$ = sysInfo.deviceUniqueID$
    m.deviceModel$ = sysInfo.deviceModel$
    m.deviceFamily$ = sysInfo.deviceFamily$
    m.deviceFWVersionNumber% = sysInfo.deviceFWVersionNumber%
    
    m.diagnosticCodes = diagnosticCodes

End Sub


Sub OpenLogFile()

    m.logFile = 0

    if not m.logging then return

    m.logFileLength = 0

    m.logFile = CreateObject("roReadFile", "log.txt")
    if type(m.logFile) = "roReadFile" then
        m.logFile.SeekToEnd()
        m.logFileLength = m.logFile.CurrentPosition()
        m.logFile = 0
    endif

    m.logFile = CreateObject("roAppendFile", "log.txt")
    if type(m.logFile)<>"roAppendFile" then
        print "unable to open log.txt"
        stop
    endif

    return

End Sub


Sub CloseLogFile()

    if not m.logging then return

    m.logFile.Flush()
    m.logFile = 0

    return

End Sub


Sub OldFlushLogFile()

    if not m.logging then return

    if m.logFileLength > 1000000 then
        print  "### - Rotate Log Files - ###"
        m.logFile.SendLine("### - Rotate Log Files - ###")
    endif

    m.logFile.Flush()

    if m.logFileLength > 1000000 then
        m.RotateLogFiles()
    endif

    return

End Sub


Sub WriteToLog(eventType$ As String, eventData$ As String, eventResponseCode$ As String, accountName$ As String)

    if not m.logging then return

    if m.debug then print "### write_event"

    ' write out the following info
    '   Timestamp, Device ID, Account Name, Event Type, Event Data, Response Code, Software Version, Firmware Version
    eventDateTime = m.systemTime.GetLocalDateTime()
    eventDataStr$ = eventDateTime + " " + accountName$ + " " + eventType$ + " " + eventData$ + " " + eventResponseCode$ + " recovery_runsetup.brs " + m.setupVersion$ + " " + m.deviceFWVersion$
    if m.debug then print "eventDataStr$ = ";eventDataStr$
    m.logFile.SendLine(eventDataStr$)

    m.logFileLength = m.logFileLength + len(eventDataStr$) + 14

    m.OldFlushLogFile()

    return

End Sub


Sub RotateLogFiles()

    log3 = CreateObject("roReadFile", "log_3.txt")
    if type(log3)="roReadFile" then
        log3 = 0
		DeleteFile("log_3.txt")
    endif

    log2 = CreateObject("roReadFile", "log_2.txt")
    if type(log2)="roReadFile" then
        log2 = 0
        MoveFile("log_2.txt", "log_3.txt")
    endif

    m.logFile = 0
    MoveFile("log.txt", "log_2.txt")

    m.OpenLogFile()

    return

End Sub


Sub PrintDebug(debugStr$ As String)

    if type(m) <> "roAssociativeArray" then stop
    
    if m.debug then 

        print debugStr$

        if not m.logging then return

        m.logFile.SendLine(debugStr$)
        m.logFileLength = m.logFileLength + len(debugStr$) + 1
        m.OldFlushLogFile()

    endif

    return

End Sub


Sub PrintTimestamp()

    eventDateTime = m.systemTime.GetLocalDateTime()
    if m.debug then print eventDateTime.GetString()
    if not m.logging then return
    m.logFile.SendLine(eventDateTime)
    m.OldFlushLogFile()

    return

End Sub



REM *******************************************************
REM *******************************************************
REM ***************                    ********************
REM *************** NETWORKING OBJECT  ********************
REM ***************                    ********************
REM *******************************************************
REM *******************************************************

REM
REM construct a new networking BrightScript object
REM
Function newNetworking(Setup As Object) As Object

    networking = CreateObject("roAssociativeArray")

    networking.systemTime = m.systemTime
    networking.diagnostics = m.diagnostics
    networking.logging = m.logging
    networking.msgPort = m.msgPort

    networking.InitializeNetworkDownloads = InitializeNetworkDownloads
    networking.StartSync = StartSync
    networking.URLEvent = URLEvent
    networking.PoolEvent = PoolEvent
    networking.SyncPoolProgressEvent = SyncPoolProgressEvent
    networking.GetPoolFilePath = GetPoolFilePath
        
	networking.SetPoolSizes = SetPoolSizes

    networking.AddUploadHeaders = AddUploadHeaders

    networking.SendError = SendError
    networking.SendErrorCommon = SendErrorCommon
    networking.SendErrorThenReboot = SendErrorThenReboot
    networking.SendEvent = SendEvent
    networking.SendEventCommon = SendEventCommon
    networking.SendEventThenReboot = SendEventThenReboot
    networking.SetSystemInfo = SetSystemInfo
    
' logging
    networking.UploadLogFiles = UploadLogFiles
    networking.UploadLogFileHandler = UploadLogFileHandler
    networking.uploadLogFileURLXfer = CreateObject("roUrlTransfer")
    networking.uploadLogFileURLXfer.SetPort(networking.msgPort)
    networking.uploadLogFileURL$ = ""
    networking.uploadLogFolder = "logs"
    networking.uploadLogArchiveFolder = "archivedLogs"
    networking.uploadLogFailedFolder = "failedLogs"
    networking.enableLogDeletion = true

    networking.POOL_EVENT_FILE_DOWNLOADED = 1
    networking.POOL_EVENT_FILE_FAILED = -1
    networking.POOL_EVENT_ALL_DOWNLOADED = 2
    networking.POOL_EVENT_ALL_FAILED = -2

    networking.EVENT_REALIZE_SUCCESS = 101

    networking.SYNC_ERROR_CANCELLED = -10001
    networking.SYNC_ERROR_CHECKSUM_MISMATCH = -10002
    networking.SYNC_ERROR_EXCEPTION = -10003
    networking.SYNC_ERROR_DISK_ERROR = -10004
    networking.SYNC_ERROR_POOL_UNSATISFIED = -10005

    networking.URL_EVENT_COMPLETE = 1

	du = CreateObject("roStorageInfo", "./")
    networking.cardSizeInMB = du.GetSizeInMegabytes()
    du = 0

	networking.assetPool = CreateObject("roAssetPool", "pool")

    return networking

End Function


Function InitializeNetworkDownloads(playbackLoggingEnabled$ As String, eventLoggingEnabled$ As String, stateLoggingEnabled$ As String, diagnosticLoggingEnabled$ As String, variableLoggingEnabled$ As String, uploadLogFilesAtBoot$ As String, uploadLogFilesAtSpecificTime$ As String, uploadLogFilesTime$ As String) As Boolean

	' Load up the current sync specification so we have it ready
	m.currentSync = CreateObject("roSyncSpec")
	if not m.currentSync.ReadFromFile("current-sync.xml") then
	    m.diagnostics.PrintDebug("### No current sync state available")
		stop
	endif

    registrySection = CreateObject("roRegistrySection", "networking")

    baseURL$ = m.currentSync.LookupMetadata("client", "base")
	m.nextURL$ = baseURL$ + m.currentSync.LookupMetadata("client", "next")
    m.user$ = m.currentSync.LookupMetadata("server", "user")
    m.password$ = m.currentSync.LookupMetadata("server", "password")
    if m.user$<>"" and m.password$<>"" then
        m.setUserAndPassword = true
		enableUnsafeAuthentication$ = m.currentSync.LookupMetadata("server", "enableUnsafeAuthentication")
		if lcase(enableUnsafeAuthentication$) = "true" then
			m.enableUnsafeAuthentication = true
		else
			m.enableUnsafeAuthentication = false
		endif
    else
        m.setUserAndPassword = false
		m.enableUnsafeAuthentication = false
    endif
    m.uploadLogFileURL$ = baseURL$ + m.currentSync.LookupMetadata("client", "uploadlogs")

	ClearRegistryKeys(registrySection)

	' retrieve and parse featureMinRevs.xml
	featureMinRevs = ParseFeatureMinRevs()

	modelSupportsWifi = GetModelSupportsWifi()

' Hostname
	SetHostname(m.currentSync)

' Wireless parameters
	useWireless = SetWirelessParameters(m.currentSync, registrySection, modelSupportsWifi)

' Wired parameters
	SetWiredParameters(m.currentSync, registrySection, useWireless)

' Network configurations
	if m.currentSync.LookupMetadata("client", "useWireless") = "yes"
		if modelSupportsWifi then
			wifiNetworkingParameters = SetNetworkConfiguration(m.currentSync, registrySection, "", "")
			ethernetNetworkingParameters = SetNetworkConfiguration(m.currentSync, registrySection, "_2", "2")
		else
			' if the user specified wireless but the system doesn't support it, use the parameters specified for wired (the secondary parameters)
			ethernetNetworkingParameters = SetNetworkConfiguration(m.currentSync, registrySection, "_2", "")
		endif
	else
		ethernetNetworkingParameters = SetNetworkConfiguration(m.currentSync, registrySection, "", "")
	endif

' determine bindings

	contentXfersEnabledWired$ = m.currentSync.LookupMetadata("client", "contentDataTypeEnabledWired")
	contentXfersEnabledWireless$ = m.currentSync.LookupMetadata("client", "contentDataTypeEnabledWireless")

	contentXfersEnabledWired = GetDataTransferEnabled(contentXfersEnabledWired$)
	contentXfersEnabledWireless = GetDataTransferEnabled(contentXfersEnabledWireless$)
	m.contentXfersBinding% = GetBinding(contentXfersEnabledWired, contentXfersEnabledWireless)

	logUploadsXfersEnabledWired$ = m.currentSync.LookupMetadata("client", "logUploadsDataTypeEnabledWired")
	logUploadsXfersEnabledWireless$ = m.currentSync.LookupMetadata("client", "logUploadsDataTypeEnabledWireless")

	logUploadsXfersEnabledWired = GetDataTransferEnabled(logUploadsXfersEnabledWired$)
	logUploadsXfersEnabledWireless = GetDataTransferEnabled(logUploadsXfersEnabledWireless$)
	m.logUploadsXfersBinding% = GetBinding(logUploadsXfersEnabledWired, logUploadsXfersEnabledWireless)
    
' network configuration parameters. read from sync spec, set roNetworkConfiguration, write to registry
	proxySpec$ = GetProxy(m.currentSync, registrySection)
	bypassProxyHosts = GetBypassProxyHosts(proxySpec$, m.currentSync)	

    timeServer$ = m.currentSync.LookupMetadata("client", "timeServer")
    registrySection.Write("ts", timeServer$)

' configure ethernet
	networkConnectionPriorityWired$ = GetEntry(m.currentSync, "networkConnectionPriorityWired")
	ConfigureEthernet(ethernetNetworkingParameters, networkConnectionPriorityWired$, timeServer$, proxySpec$, bypassProxyHosts, featureMinRevs)

' configure wifi if specified and device supports wifi
	if useWireless = "yes" then
		networkConnectionPriorityWireless$ = GetEntry(m.currentSync, "networkConnectionPriorityWireless")
		ssid$ = GetEntry(m.currentSync, "ssid")
		passphrase$ = GetEntry(m.currentSync, "passphrase")
		ConfigureWifi(wifiNetworkingParameters, ssid$, passphrase$, networkConnectionPriorityWireless$, timeServer$, proxySpec$, bypassProxyHosts, featureMinRevs)
	endif

' if a device is setup to not use wireless, ensure that wireless is not used (for wireless model only)
	if useWireless = "no" and modelSupportsWifi then
		DisableWireless()
	endif

' net connect parameters. read from sync spec, write to registry
    timeBetweenNetConnects$ = m.currentSync.LookupMetadata("client", "timeBetweenNetConnects")
    contentDownloadsRestricted = m.currentSync.LookupMetadata("client", "contentDownloadsRestricted")
    contentDownloadRangeStart = m.currentSync.LookupMetadata("client", "contentDownloadRangeStart")
    contentDownloadRangeLength = m.currentSync.LookupMetadata("client", "contentDownloadRangeLength")

    if timeBetweenNetConnects$ = "" then stop

    if type(registrySection)<>"roRegistrySection" then print "Error: Unable to create roRegistrySection":stop
    registrySection.Write("tbnc", timeBetweenNetConnects$)
    registrySection.Write("cdr", contentDownloadsRestricted)
    registrySection.Write("cdrs", contentDownloadRangeStart)
    registrySection.Write("cdrl", contentDownloadRangeLength)

' if a device is setup to not use wireless, ensure that wireless is not used (for wireless model only)
	if useWireless = "no" and modelSupportsWifi then
		DisableWireless()
	endif

' diagnostic web server
	SetDWS(m.currentSync, registrySection)

' channel scanning data
	SetupTunerData()

' remote snapshot
	SetRemoteSnapshot(m.currentSync, registrySection)

' idle screen color
	SetIdleColor(m.currentSync, registrySection)

' custom splash screen
	SetCustomSplashScreen(m.currentSync, registrySection, featureMinRevs)

' local web server
	SetLWS(m.currentSync, registrySection)

' unit name parameters. read from sync spec, write to registry
    unitName$ = m.currentSync.LookupMetadata("client", "unitName")
    unitNamingMethod$ = m.currentSync.LookupMetadata("client", "unitNamingMethod")
    unitDescription$ = m.currentSync.LookupMetadata("client", "unitDescription")

    registrySection.Write("un", unitName$)
    registrySection.Write("unm", unitNamingMethod$)
    registrySection.Write("ud", unitDescription$)

' timezone setting from setup
    timezone = m.currentSync.LookupMetadata("client", "timezone")
    if timezone <> "" then
        m.systemTime.SetTimeZone(timezone)
    endif

' registry writes complete - flush it    
    registrySection.Flush()

' perform network diagnostics if enabled
	networkDiagnosticsEnabled = GetBooleanSyncSpecEntry(m.currentSync, "networkDiagnosticsEnabled")
	testEthernetEnabled = GetBooleanSyncSpecEntry(m.currentSync, "testEthernetEnabled")
	testWirelessEnabled = GetBooleanSyncSpecEntry(m.currentSync, "testWirelessEnabled")
	testInternetEnabled = GetBooleanSyncSpecEntry(m.currentSync, "testInternetEnabled")

	if networkDiagnosticsEnabled then
		PerformNetworkDiagnostics(testEthernetEnabled, testWirelessEnabled, testInternetEnabled)
	endif

    m.diagnostics.PrintTimestamp()
	m.diagnostics.PrintDebug("### Currently active sync list suggests next URL of " + m.nextURL$)

	if m.nextURL$ = "" then stop

' Check for updates every minute
	m.checkAlarm = CreateObject("roTimer")
	m.checkAlarm.SetPort(m.msgPort)
	m.checkAlarm.SetDate(-1, -1, -1)
	m.checkAlarm.SetTime(-1, -1, 0, 0)
	if not m.checkAlarm.Start() then stop	

    return true

End Function


Sub StartSync()

' Call when you want to start a sync operation

    m.diagnostics.PrintTimestamp()
    m.diagnostics.PrintDebug("### start_sync")
    
	if type(m.syncPool) = "roSyncPool" then
' This should be improved in the future to work out
' whether the sync spec we're currently satisfying
' matches the one that we're currently downloading or
' not.
        m.diagnostics.PrintDebug("### sync already active so we'll let it continue")
        m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_SYNC_ALREADY_ACTIVE, "")
		return
	endif

	m.xfer = CreateObject("roUrlTransfer")
	m.xfer.SetPort(m.msgPort)

	' We've read in our current sync. Talk to the server to get
	' the next sync. Note that we use the current-sync.xml because
	' we need to tell the server what we are _currently_ running not
	' what we might be running at some point in the future.

	m.diagnostics.PrintDebug("### Looking for new sync list from " + m.nextURL$)
	m.xfer.SetUrl(m.nextURL$)
    if m.setUserAndPassword then m.xfer.SetUserAndPassword(m.user$, m.password$)
	m.xfer.EnableUnsafeAuthentication(m.enableUnsafeAuthentication)
	m.xfer.SetHeaders(m.currentSync.GetMetadata("server"))
' Add device unique identifier, timezone
    m.xfer.AddHeader("DeviceID", m.deviceUniqueID$)
    m.xfer.AddHeader("DeviceFWVersion", m.deviceFWVersion$)
    m.xfer.AddHeader("DeviceSWVersion", "autorun-setup.brs " + m.setupVersion$)
    m.xfer.AddHeader("timezone", m.systemTime.GetTimeZone())

' Add card size
	m.xfer.AddHeader("storage-size", str(m.cardSizeInMB))

    m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_CHECK_CONTENT, m.nextURL$)
	
	print "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& binding for StartSync is ";m.contentXfersBinding%
	ok = m.xfer.BindToInterface(m.contentXfersBinding%)
	if not ok then stop
	
	if not m.xfer.AsyncGetToFile("tmp:new-sync.xml") then stop

    return
    
End Sub


Sub SetPoolSizes( syncSpec As Object ) As Object

	limitStorageSpace$ = syncSpec.LookupMetadata("client", "limitStorageSpace")
	if lcase(limitStorageSpace$) = "true" then
		limitStorageSpace = true
		spaceLimitedByAbsoluteSize = syncSpec.LookupMetadata("client", "spaceLimitedByAbsoluteSize")
		publishedDataSizeLimitMB = syncSpec.LookupMetadata("client", "publishedDataSizeLimitMB")
		publishedDataSizeLimitPercentage = syncSpec.LookupMetadata("client", "publishedDataSizeLimitPercentage")
	else
		limitStorageSpace = false
	endif

	if limitStorageSpace then

		if lcase(spaceLimitedByAbsoluteSize) <> "true" then

			' convert from percentage settings to absolute settings
			du = CreateObject("roStorageInfo", "./")
			totalCardSizeMB% = du.GetSizeInMegabytes()

			' pool size for published data
			publishedDataSizeLimitPercentage% = int(val(publishedDataSizeLimitPercentage))
			maximumPublishedDataPoolSizeMB% = publishedDataSizeLimitPercentage% * totalCardSizeMB% / 100

		else

			maximumPublishedDataPoolSizeMB% = int(val(publishedDataSizeLimitMB))

		endif

		ok = m.assetPool.SetMaximumPoolSizeMegabytes( maximumPublishedDataPoolSizeMB% )
		' if not ok ??

	else
		' clear prior settings
		ok = m.assetPool.SetMaximumPoolSizeMegabytes( -1 )
		' if not ok ??

	endif

End Sub


' Call when we get a URL event
Sub URLEvent(msg As Object)

    m.diagnostics.PrintTimestamp()
    m.diagnostics.PrintDebug("### url_event")

	if type (m.xfer) <> "roUrlTransfer" then return
	if msg.GetSourceIdentity() = m.xfer.GetIdentity() then
	    if msg.GetInt() = m.URL_EVENT_COMPLETE then
		    xferInUse = false
		    if msg.GetResponseCode() = 200 then
			    m.newSync = CreateObject("roSyncSpec")
			    if m.newSync.ReadFromFile("tmp:new-sync.xml") then
                    m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_SYNCSPEC_RECEIVED, "YES")
                    m.diagnostics.PrintDebug("### Server gave us spec: " + m.newSync.GetName())
				    readySync = CreateObject("roSyncSpec")
				    if readySync.ReadFromFile("ready-sync.xml") then
					    if m.newSync.EqualTo(readySync) then
                            m.diagnostics.PrintDebug("### Server has given us a spec that matches ready-sync. Nothing more to do.")
						    DeleteFile("tmp:new-sync.xml")
						    readySync = 0
						    m.newSync = 0
						    return
					    endif
				    endif

' Anything the server has given us supersedes ready-sync.xml so we'd better delete it and cancel its alarm
				    DeleteFile("ready-sync.xml")

' Log the start of sync list download
                    m.logging.WriteDiagnosticLogEntry( m.diagnosticCodes.EVENT_DOWNLOAD_START, "")
                    m.SendEvent("StartSyncListDownload", m.newSync.GetName(), "")

					m.SetPoolSizes( m.newSync )

				    m.syncPool = CreateObject("roSyncPool", "pool")
				    m.syncPool.SetPort(m.msgPort)
                    m.syncPool.SetMinimumTransferRate(1000,900)
                    m.syncPool.SetFileProgressIntervalSeconds(15)
                    if m.setUserAndPassword then m.syncPool.SetUserAndPassword(m.user$, m.password$)
					m.syncPool.EnableUnsafeAuthentication(m.enableUnsafeAuthentication)
                    m.syncPool.SetHeaders(m.newSync.GetMetadata("server"))
                    m.syncPool.AddHeader("DeviceID", m.deviceUniqueID$)

					print "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& binding for syncPool is ";m.contentXfersBinding%
					ok = m.syncPool.BindToInterface(m.contentXfersBinding%)
					if not ok then stop

' implies dodgy XML, or something is already running. could happen if server sends down bad xml.
				    if not m.syncPool.AsyncDownload(m.newSync) then
                        m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_SYNCSPEC_DOWNLOAD_IMMEDIATE_FAILURE, m.syncPool.GetFailureReason())
				        m.diagnostics.PrintTimestamp()
                        m.diagnostics.PrintDebug("### AsyncDownload failed: " + m.syncPool.GetFailureReason())
					    m.newSync = 0
					    m.SendError("AsyncDownloadFailure", m.syncPool.GetFailureReason(), "", m.newSync.GetName())
				    endif
' implies dodgy XML, or something is already running. could happen if server sends down bad xml.
			    else
			        m.diagnostics.PrintDebug("### Failed to read new-sync.xml")
			        m.SendError("Failed to read new-sync.xml", "", "", m.newSync.GetName())
				    m.newSync = 0
			    endif
		    else if msg.GetResponseCode() = 404 then
                m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_NO_SYNCSPEC_AVAILABLE, "404")
                m.diagnostics.PrintDebug("### Server has no sync list for us: " + str(msg.GetResponseCode()))
' The server has no new sync for us. That means if we have one lined up then we should destroy it.
			    DeleteFile("ready-sync.xml")
		    else
    ' retry - server returned something other than a 200 or 404
                m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_RETRIEVE_SYNCSPEC_FAILURE, str(msg.GetResponseCode()))
                m.diagnostics.PrintDebug("### Failed to download sync list.")
                m.SendError("Failed to download sync list", "", str(msg.GetResponseCode()), "")
		    endif
	    else
	    	m.diagnostics.PrintDebug("### Progress URL event - we don't know about those.")
	    endif

	else
	    m.diagnostics.PrintDebug("### url_event from beyond this world: " + str(msg.GetSourceIdentity()) + ", " + str(msg.GetResponseCode()) + ", " + str(msg.GetInt()))
        m.SendError("url_event from beyond this world", "", "", str(msg.GetSourceIdentity()))
	endif
	
	return

End Sub


Sub SyncPoolProgressEvent(msg As Object)

    m.diagnostics.PrintDebug("### File download progress " + msg.GetFileName() + str(msg.GetCurrentFilePercentage()))

    m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_FILE_DOWNLOAD_PROGRESS, msg.GetFileName() + chr(9) + str(msg.GetCurrentFilePercentage()))

End Sub


' Call when we get a sync event
Sub PoolEvent(msg As Object)
    m.diagnostics.PrintTimestamp()
    m.diagnostics.PrintDebug("### pool_event")
	if type(m.syncPool) <> "roSyncPool" then
        m.diagnostics.PrintDebug("### pool_event but we have no object")
		return
	endif
	if msg.GetSourceIdentity() = m.syncPool.GetIdentity() then
		if (msg.GetEvent() = m.POOL_EVENT_FILE_DOWNLOADED) then
            m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_FILE_DOWNLOAD_COMPLETE, msg.GetName())
            m.diagnostics.PrintDebug("### File downloaded " + msg.GetName())
		elseif (msg.GetEvent() = m.POOL_EVENT_FILE_FAILED) then
            m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_FILE_DOWNLOAD_FAILURE, msg.GetName() + chr(9) + msg.GetFailureReason())
            m.diagnostics.PrintDebug("### File failed " + msg.GetName() + ": " + msg.GetFailureReason())
            m.SendError("FileDownloadFailure", msg.GetFailureReason(), str(msg.GetResponseCode()), msg.GetName())
		elseif (msg.GetEvent() = m.POOL_EVENT_ALL_DOWNLOADED) then
            m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_DOWNLOAD_COMPLETE, "")		
            m.diagnostics.PrintDebug("### All downloaded for " + m.newSync.GetName())

' Log the end of sync list download
            m.SendEvent("EndSyncListDownload", m.newSync.GetName(), str(msg.GetResponseCode()))

' Save to current-sync.xml then do cleanup
		    if not m.newSync.WriteToFile("current-sync.xml") then stop
            timezone = m.newSync.LookupMetadata("client", "timezone")
            if timezone <> "" then
                m.systemTime.SetTimeZone(timezone)
            endif
			
            m.diagnostics.PrintDebug("### DOWNLOAD COMPLETE")
            
            m.spf = CreateObject("roSyncPoolFiles", "pool", m.newSync)
            
			newSyncSpecScriptsOnly  = m.newSync.FilterFiles("download", { group: "script" } )
			event = m.syncPool.Realize(newSyncSpecScriptsOnly, "/")
			if event.GetEvent() <> m.EVENT_REALIZE_SUCCESS then
		        m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_REALIZE_FAILURE, stri(event.GetEvent()) + chr(9) + event.GetName() + chr(9) + event.GetFailureReason())
				m.diagnostics.PrintDebug("### Realize failed " + stri(event.GetEvent()) + chr(9) + event.GetName() + chr(9) + event.GetFailureReason() )
				m.SendError("RealizeFailure", event.GetName(), event.GetFailureReason(), str(event.GetEvent()))
			else
	            m.SendEventThenReboot("DownloadComplete", m.newSync.GetName(), "")
			endif

			DeleteFile("tmp:new-sync.xml")
			m.newSync = invalid
			m.syncPool = invalid
		elseif (msg.GetEvent() = m.POOL_EVENT_ALL_FAILED) then
            m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_SYNCSPEC_DOWNLOAD_FAILURE, msg.GetFailureReason())		
            m.diagnostics.PrintDebug("### Sync failed: " + msg.GetFailureReason())
            m.SendError("SyncFailure", msg.GetFailureReason(), str(msg.GetResponseCode()), "")
			m.newSync = invalid
			m.syncPool = invalid
		endif
	else
        m.diagnostics.PrintDebug("### pool_event from beyond this world: " + str(msg.GetSourceIdentity()))
	endif
	return

End Sub


Sub UploadLogFiles()

    if m.uploadLogFileURL$ = "" then return
    
' if a transfer is in progress, return
    m.diagnostics.PrintDebug("### Upload " + m.uploadLogFolder)
	if not m.uploadLogFileURLXfer.SetUrl(m.uploadLogFileURL$) then
        m.diagnostics.PrintDebug("### Upload " + m.uploadLogFolder + " - upload already in progress")
		return 
	end if

' see if there are any files to upload
    listOfLogFiles = MatchFiles("/" + m.uploadLogFolder, "*.log")
    if listOfLogFiles.Count() = 0 then return
    
' upload the first file    
    for each file in listOfLogFiles
        m.diagnostics.PrintDebug("### UploadLogFiles " + file + " to " + m.uploadLogFileURL$)
        fullFilePath = m.uploadLogFolder + "/" + file
                
        contentDisposition$ = GetContentDisposition(file)
        m.AddUploadHeaders(m.uploadLogFileURLXfer, contentDisposition$)

		print "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& binding for UploadLogFiles is ";m.logUploadsXfersBinding%
		ok = m.uploadLogFileURLXfer.BindToInterface(m.logUploadsXfersBinding%)
		if not ok then stop

        ok = m.uploadLogFileURLXfer.AsyncPostFromFile(fullFilePath)
        if not ok then stop
        m.logFileUpload = fullFilePath
        m.logFile$ = file
        return
    next
    
End Sub


Sub UploadLogFileHandler(msg As Object)
	    	    
    if msg.GetResponseCode() = 200 then

        if type(m.logFileUpload) = "roString" then
            m.diagnostics.PrintDebug("###  UploadLogFile XferEvent - successfully uploaded " + m.logFileUpload)
            if m.enableLogDeletion then
                DeleteFile(m.logFileUpload)
            else
                target$ = m.uploadLogArchiveFolder + "/" + m.logFile$
                ok = MoveFile(m.logFileUpload, target$)
            endif
            m.logFileUpload = invalid		    
        endif
        
    else
        
        if type(m.logFileUpload) = "roString" then
            m.diagnostics.PrintDebug("### Failed to upload log file " + m.logFileUpload + ", error code = " + str(msg.GetResponseCode()))

            ' move file so that the script doesn't try to upload it again immediately
            target$ = m.uploadLogFailedFolder + "/" + m.logFile$
            ok = MoveFile(m.logFileUpload, target$)

        endif

        m.logging.WriteDiagnosticLogEntry(m.diagnosticCodes.EVENT_LOGFILE_UPLOAD_FAILURE, str(msg.GetResponseCode()))
        
	endif
	
	m.UploadLogFiles()
		
End Sub


Sub AddUploadHeaders(url As Object, contentDisposition$)

'    url.SetHeaders({})
    url.SetHeaders(m.currentSync.GetMetadata("server"))

' Add device unique identifier, timezone
    url.AddHeader("DeviceID", m.deviceUniqueID$)
    
    url.AddHeader("DeviceModel", m.deviceModel$)
    url.AddHeader("DeviceFamily", m.deviceFamily$)
    url.AddHeader("DeviceFWVersion", m.deviceFWVersion$)
    url.AddHeader("DeviceSWVersion", m.setupVersion$)
    
    url.AddHeader("utcTime", m.systemTime.GetUtcDateTime().GetString())

    url.AddHeader("Content-Type", "application/octet-stream")
    
    url.AddHeader("Content-Disposition", contentDisposition$)

End Sub


Function GetContentDisposition(file As String) As String

'Content-Disposition: form-data; name="file"; filename="UploadPlaylog.xml"

    contentDisposition$ = "form-data; name="
    contentDisposition$ = contentDisposition$ + chr(34)
    contentDisposition$ = contentDisposition$ + "file"
    contentDisposition$ = contentDisposition$ + chr(34)
    contentDisposition$ = contentDisposition$ + "; filename="
    contentDisposition$ = contentDisposition$ + chr(34)
    contentDisposition$ = contentDisposition$ + file
    contentDisposition$ = contentDisposition$ + chr(34)

    return contentDisposition$
    
End Function


Function GetPoolFilePath(fileName$ As String) As Object

    return m.spf.GetPoolFilePath(fileName$)
    
End Function


Function SendEventCommon(eventURL As Object, eventType$ As String, eventData$ As String, eventResponseCode$ As String) As String

    m.diagnostics.PrintDebug("### send_event")
    
	eventURL.SetUrl(m.event_url$)
    eventURL.AddHeader("account", m.account$)
    eventURL.AddHeader("group", m.group$)
    eventURL.AddHeader("user", m.user$)
    eventURL.AddHeader("password", m.password$)
    eventURL.AddHeader("DeviceID", m.deviceUniqueID$)
    eventURL.AddHeader("DeviceFWVersion", m.deviceFWVersion$)
    eventURL.AddHeader("DeviceSWVersion", "recovery_runsetup.brs " + m.setupVersion$)
    eventStr$ = "EventType=" + eventType$ + "&EventData=" + eventData$ + "&ResponseCode=" + eventResponseCode$

    return eventStr$

End Function


Sub SendEvent(eventType$ As String, eventData$ As String, eventResponseCode$ As String)

return

	eventURL = CreateObject("roUrlTransfer")

    eventStr$ = m.SendEventCommon(eventURL, eventType$, eventData$, eventResponseCode$)

	eventURL.AsyncPostFromString(eventStr$)

    m.diagnostics.WriteToLog(eventType$, eventData$, eventResponseCode$, m.account$)

	return

End Sub


Sub SendEventThenReboot(eventType$ As String, eventData$ As String, eventResponseCode$ As String)

    m.logging.FlushLogFile()

a=RebootSystem()
stop

	eventURL = CreateObject("roUrlTransfer")

    eventStr$ = m.SendEventCommon(eventURL, eventType$, eventData$, eventResponseCode$)

    eventPort = CreateObject("roMessagePort")
	eventURL.SetPort(eventPort)
	eventURL.AsyncPostFromString(eventStr$)

    m.diagnostics.WriteToLog(eventType$, eventData$, eventResponseCode$, m.account$)

    unexpectedUrlEventCount = 0

    while true

        msg = wait(10000, eventPort)   ' wait for either a timeout (10 seconds) or a message indicating that the post was complete

        if type(msg) = "rotINT32" then
            m.diagnostics.PrintDebug("### timeout before final event posted")
            ' clear
	        a=RebootSystem()
            stop
        else if type(msg) = "roUrlEvent" then
    	    if msg.GetSourceIdentity() = eventURL.GetIdentity() then
	    	    if msg.GetResponseCode() = 200 then
                    ' clear
            	    a=RebootSystem()
                endif
            endif
        endif

        m.diagnostics.PrintDebug("### unexpected url event while waiting to reboot")
        unexpectedUrlEventCount = unexpectedUrlEventCount + 1
        if unexpectedUrlEventCount > 10 then
            m.diagnostics.PrintDebug("### reboot due to too many url events while waiting to reboot")
            ' clear
            a=RebootSystem()
        endif

    endwhile

    return

End Sub


Function SendErrorCommon(errorURL As Object, errorType$ As String, errorReason$ As String, errorResponseCode$ As String, errorData$ As String) As String

    m.diagnostics.PrintDebug("### send_error")
    
	errorURL = CreateObject("roUrlTransfer")
	errorURL.SetUrl(m.error_url$)
    errorURL.AddHeader("account", m.account$)
    errorURL.AddHeader("group", m.group$)
    errorURL.AddHeader("user", m.user$)
    errorURL.AddHeader("password", m.password$)
    errorURL.AddHeader("DeviceID", m.deviceUniqueID$)
    errorURL.AddHeader("DeviceFWVersion", m.deviceFWVersion$)
    errorURL.AddHeader("DeviceSWVersion", "recovery_runsetup.bas " + m.setupVersion$)
    errorStr$ = "ErrorType=" + errorType$ + "&FailureReason=" + errorReason$ + "&ResponseCode=" + errorResponseCode$  + "&ErrorData=" + errorData$

    return errorStr$

End Function


Sub SendError(errorType$ As String, errorReason$ As String, errorResponseCode$ As String, errorData$ As String)

return

	errorURL = CreateObject("roUrlTransfer")

    errorStr$ = m.SendErrorCommon(errorURL, errorType$, errorReason$, errorResponseCode$, errorData$)

	if not errorURL.AsyncPostFromString(errorStr$) then stop

	return

End Sub


Sub SendErrorThenReboot(errorType$ As String, errorReason$ As String, errorResponseCode$ As String, errorData$ As String)

a=RebootSystem()
return

	errorURL = CreateObject("roUrlTransfer")

    errorStr$ = m.SendErrorCommon(errorURL, errorType$, errorReason$, errorResponseCode$, errorData$)

    errorPort = CreateObject("roMessagePort")
	errorURL.SetPort(errorPort)
	if not errorURL.AsyncPostFromString(errorStr$) then stop

    unexpectedUrlErrorCount = 0

    while true

        msg = wait(10000, errorPort)   ' wait for either a timeout (10 seconds) or a message indicating that the post was complete

        if type(msg) = "rotINT32" then
            m.diagnostics.PrintDebug("### timeout before final error posted")
            ' clear
	        a=RebootSystem()
            stop
        else if type(msg) = "roUrlEvent" then
    	    if msg.GetSourceIdentity() = errorURL.GetIdentity() then
	    	    if msg.GetResponseCode() = 200 then
                    ' clear
            	    a=RebootSystem()
                endif
            endif
        endif

        m.diagnostics.PrintDebug("### unexpected url event while waiting to reboot")
        unexpectedUrlErrorCount = unexpectedUrlErrorCount + 1
        if unexpectedUrlErrorCount > 10 then
            m.diagnostics.PrintDebug("### reboot due to too many url events while waiting to reboot")
            ' clear
            a=RebootSystem()
        endif

    endwhile

    return

End Sub


REM *******************************************************
REM *******************************************************
REM ***************                    ********************
REM *************** LOGGING OBJECT     ********************
REM ***************                    ********************
REM *******************************************************
REM *******************************************************

REM
REM construct a new logging BrightScript object
REM
Function newLogging() As Object

    logging = CreateObject("roAssociativeArray")
    
    logging.msgPort = m.msgPort
    logging.systemTime = m.systemTime
    logging.diagnostics = m.diagnostics
    
    logging.SetSystemInfo = SetSystemInfo

    logging.registrySection = CreateObject("roRegistrySection", "networking")
    if type(logging.registrySection) <> "roRegistrySection" then print "Error: Unable to create roRegistrySection":stop
    logging.CreateLogFile = CreateLogFile
    logging.MoveExpiredCurrentLog = MoveExpiredCurrentLog
    logging.MoveCurrentLog = MoveCurrentLog
    logging.InitializeLogging = InitializeLogging
    logging.ReinitializeLogging = ReinitializeLogging
    logging.InitializeCutoverTimer = InitializeCutoverTimer
    logging.WritePlaybackLogEntry = WritePlaybackLogEntry
    logging.WriteEventLogEntry = WriteEventLogEntry
    logging.WriteDiagnosticLogEntry = WriteDiagnosticLogEntry
    logging.PushLogFile = PushLogFile
    logging.CutoverLogFile = CutoverLogFile
    logging.HandleTimerEvent = HandleLoggingTimerEvent
    logging.PushLogFilesOnBoot = PushLogFilesOnBoot
    logging.OpenOrCreateCurrentLog = OpenOrCreateCurrentLog
    logging.DeleteExpiredFiles = DeleteExpiredFiles
    logging.DeleteOlderFiles = DeleteOlderFiles
    logging.FlushLogFile = FlushLogFile
    logging.logFile = invalid
    
    logging.uploadLogFolder = "logs"
    logging.uploadLogArchiveFolder = "archivedLogs"
    logging.uploadLogFailedFolder = "failedLogs"
    logging.logFileUpload = invalid
    
    logging.playbackLoggingEnabled = false
    logging.eventLoggingEnabled = false
    logging.stateLoggingEnabled = false
    logging.diagnosticLoggingEnabled = false
    logging.variableLoggingEnabled = false
    logging.uploadLogFilesAtBoot = false
    logging.uploadLogFilesAtSpecificTime = false
    logging.uploadLogFilesTime% = 0
    
    CreateDirectory("logs")
    CreateDirectory("currentLog")
    CreateDirectory("archivedLogs")
    CreateDirectory("failedLogs")

    return logging
    
End Function


Function CreateLogFile(logDateKey$ As String, logCounterKey$ As String) As Object

    dtLocal = m.systemTime.GetLocalDateTime()
    year$ = Right(stri(dtLocal.GetYear()), 2)
    month$ = StripLeadingSpaces(stri(dtLocal.GetMonth()))
    if len(month$) = 1 then
        month$ = "0" + month$
    endif
    day$ = StripLeadingSpaces(stri(dtLocal.GetDay()))
    if len(day$) = 1 then
        day$ = "0" + day$
    endif
    dateString$ = year$ + month$ + day$
    
    logDate$ = m.registrySection.Read(logDateKey$)
    logCounter$ = m.registrySection.Read(logCounterKey$)
    
    if logDate$ = "" or logCounter$ = "" then
        logCounter$ = "000"
    else if logDate$ <> dateString$ then
        logCounter$ = "000"
    endif
    logDate$ = dateString$
    
    localFileName$ = "BrightSign" + "Log." + m.deviceUniqueID$ + "-" + dateString$ + logCounter$ + ".log"

' at a later date, move this code to the point where the file has been uploaded successfully
    m.registrySection.Write(logDateKey$, logDate$)
    
    logCounter% = val(logCounter$)
    logCounter% = logCounter% + 1
    if logCounter% > 999 then
        logCounter% = 0
    endif
    logCounter$ = StripLeadingSpaces(stri(logCounter%))
    if len(logCounter$) = 1 then
        logCounter$ = "00" + logCounter$
    else if len(logCounter$) = 2 then
        logCounter$ = "0" + logCounter$
    endif
    m.registrySection.Write(logCounterKey$, logCounter$)
 
    fileName$ = "currentLog/" + localFileName$
    logFile = CreateObject("roCreateFile", fileName$)
    m.diagnostics.PrintDebug("Create new log file " + localFileName$)
    
    t$ = chr(9)
    
    ' version
    header$ = "BrightSignLogVersion"+t$+"1"
    logFile.SendLine(header$)
    
    ' serial number
    header$ = "SerialNumber"+t$+m.deviceUniqueID$
    logFile.SendLine(header$)
    
    ' group id
    if type(m.networking.currentSync) = "roSyncSpec" then
        header$ = "Account"+t$+m.networking.currentSync.LookupMetadata("server", "account")
        logFile.SendLine(header$)
        header$ = "Group"+t$+m.networking.currentSync.LookupMetadata("server", "group")
        logFile.SendLine(header$)
    endif
    
    ' timezone
    header$ = "Timezone"+t$+m.systemTime.GetTimeZone()
    logFile.SendLine(header$)

    ' timestamp of log creation
    header$ = "LogCreationTime"+t$+m.systemTime.GetLocalDateTime().GetString()
    logFile.SendLine(header$)
    
    ' ip address
    nc = CreateObject("roNetworkConfiguration", 0)
    if type(nc) = "roNetworkConfiguration" then
        currentConfig = nc.GetCurrentConfig()
        nc = invalid
        ipAddress$ = currentConfig.ip4_address
        header$ = "IPAddress"+t$+ipAddress$
        logFile.SendLine(header$)
    endif
    
    ' fw version
    header$ = "FWVersion"+t$+m.deviceFWVersion$
    logFile.SendLine(header$)
    
    ' script version
    header$ = "ScriptVersion"+t$+m.setupVersion$
    logFile.SendLine(header$)

    ' custom script version
    header$ = "CustomScriptVersion"+t$+""
    logFile.SendLine(header$)

    ' model
    header$ = "Model"+t$+m.deviceModel$
    logFile.SendLine(header$)

    logFile.AsyncFlush()
    
    return logFile
    
End Function


Sub MoveExpiredCurrentLog()

    dtLocal = m.systemTime.GetLocalDateTime()
    currentDate$ = StripLeadingSpaces(stri(dtLocal.GetDay()))
    if len(currentDate$) = 1 then
        currentDate$ = "0" + currentDate$
    endif

    listOfPendingLogFiles = MatchFiles("/currentLog", "*")
        
    for each file in listOfPendingLogFiles
    
        logFileDate$ = left(right(file, 9), 2)
    
        if logFileDate$ <> currentDate$ then
            sourceFilePath$ = "currentLog/" + file
            destinationFilePath$ = "logs/" + file
            CopyFile(sourceFilePath$, destinationFilePath$)
            DeleteFile(sourceFilePath$)
        endif
        
    next

End Sub


Sub MoveCurrentLog()

    listOfPendingLogFiles = MatchFiles("/currentLog", "*")
    for each file in listOfPendingLogFiles
        sourceFilePath$ = "currentLog/" + file
        destinationFilePath$ = "logs/" + file
        CopyFile(sourceFilePath$, destinationFilePath$)
        DeleteFile(sourceFilePath$)
    next
    
End Sub


Sub InitializeLogging(playbackLoggingEnabled As Boolean, eventLoggingEnabled As Boolean, stateLoggingEnabled As Boolean, diagnosticLoggingEnabled As Boolean, variableLoggingEnabled As Boolean, uploadLogFilesAtBoot As Boolean, uploadLogFilesAtSpecificTime As Boolean, uploadLogFilesTime% As Integer)

    m.DeleteExpiredFiles()
    
    m.playbackLoggingEnabled = playbackLoggingEnabled
    m.eventLoggingEnabled = eventLoggingEnabled
    m.stateLoggingEnabled = stateLoggingEnabled
    m.diagnosticLoggingEnabled = diagnosticLoggingEnabled
    m.variableLoggingEnabled = variableLoggingEnabled
    m.uploadLogFilesAtBoot = uploadLogFilesAtBoot
    m.uploadLogFilesAtSpecificTime = uploadLogFilesAtSpecificTime
    m.uploadLogFilesTime% = uploadLogFilesTime%

    m.loggingEnabled = playbackLoggingEnabled or eventLoggingEnabled or stateLoggingEnabled or diagnosticLoggingEnabled or variableLoggingEnabled
    m.uploadLogsEnabled = uploadLogFilesAtBoot or uploadLogFilesAtSpecificTime  
     
    if m.uploadLogFilesAtBoot then
        m.PushLogFilesOnBoot()
    endif
    
    m.MoveExpiredCurrentLog()

    if m.loggingEnabled then m.OpenOrCreateCurrentLog()
    
    m.InitializeCutoverTimer()
    
End Sub


Sub ReinitializeLogging(playbackLoggingEnabled As Boolean, eventLoggingEnabled As Boolean, stateLoggingEnabled As Boolean, diagnosticLoggingEnabled As Boolean, variableLoggingEnabled As Boolean, uploadLogFilesAtBoot As Boolean, uploadLogFilesAtSpecificTime As Boolean, uploadLogFilesTime% As Integer)

    if playbackLoggingEnabled = m.playbackLoggingEnabled and eventLoggingEnabled = m.eventLoggingEnabled and stateLoggingEnabled = m.stateLoggingEnabled and diagnosticLoggingEnabled = m.diagnosticLoggingEnabled and variableLoggingEnabled = m.variableLoggingEnabled and uploadLogFilesAtBoot = m.uploadLogFilesAtBoot and uploadLogFilesAtSpecificTime = m.uploadLogFilesAtSpecificTime and uploadLogFilesTime% = m.uploadLogFilesTime% then return
    
    if type(m.cutoverTimer) = "roTimer" then
        m.cutoverTimer.Stop()
        m.cutoverTimer = invalid
    endif

    m.playbackLoggingEnabled = playbackLoggingEnabled
    m.eventLoggingEnabled = eventLoggingEnabled
    m.stateLoggingEnabled = stateLoggingEnabled
    m.diagnosticLoggingEnabled = diagnosticLoggingEnabled
    m.variableLoggingEnabled = variableLoggingEnabled
    m.uploadLogFilesAtBoot = uploadLogFilesAtBoot
    m.uploadLogFilesAtSpecificTime = uploadLogFilesAtSpecificTime
    m.uploadLogFilesTime% = uploadLogFilesTime%

    m.loggingEnabled = playbackLoggingEnabled or eventLoggingEnabled or stateLoggingEnabled or diagnosticLoggingEnabled  or variableLoggingEnabled
    m.uploadLogsEnabled = uploadLogFilesAtBoot or uploadLogFilesAtSpecificTime  

    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" and m.loggingEnabled then
        m.OpenOrCreateCurrentLog()
    endif
            
    m.InitializeCutoverTimer()

End Sub


Sub InitializeCutoverTimer()

    if m.uploadLogFilesAtSpecificTime then
        hour% = m.uploadLogFilesTime% / 60
        minute% = m.uploadLogFilesTime% - (hour% * 60)
    else if not m.uploadLogsEnabled then
        hour% = 0
        minute% = 0
    endif
    
    if m.uploadLogFilesAtSpecificTime or not m.uploadLogsEnabled then
        m.cutoverTimer = CreateObject("roTimer")
        m.cutoverTimer.SetPort(m.msgPort)
        m.cutoverTimer.SetDate(-1, -1, -1)
        m.cutoverTimer.SetTime(hour%, minute%, 0, 0)
        m.cutoverTimer.Start()    
    endif
    
End Sub


Sub DeleteExpiredFiles()

    ' delete any files that are more than 10 days old
    
    dtExpired = m.systemTime.GetLocalDateTime()
    dtExpired.SubtractSeconds(60 * 60 * 24 * 10)
    
    ' look in the following folders
    '   logs
    '   failedLogs
    '   archivedLogs
    
    m.DeleteOlderFiles("logs", dtExpired)
    m.DeleteOlderFiles("failedLogs", dtExpired)
    m.DeleteOlderFiles("archivedLogs", dtExpired)
    
End Sub


Sub DeleteOlderFiles(folderName$ As String, dtExpired As Object)

    listOfLogFiles = MatchFiles("/" + folderName$, "*")
        
    for each file in listOfLogFiles
    
        year$ = "20" + left(right(file,13), 2)
        month$ = left(right(file,11), 2)
        day$ = left(right(file, 9), 2)
        dtFile = CreateObject("roDateTime")
        dtFile.SetYear(int(val(year$)))
        dtFile.SetMonth(int(val(month$)))
        dtFile.SetDay(int(val(day$)))
               
        if dtFile < dtExpired then
            fullFilePath$ = "/" + folderName$ + "/" + file
            m.diagnostics.PrintDebug("Delete expired log file " + fullFilePath$)
            DeleteFile(fullFilePath$)
        endif
        
    next

End Sub


Sub FlushLogFile()

    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" then return

    m.logFile.Flush()

End Sub


Sub WritePlaybackLogEntry(zoneName$ As String, startTime$ As String, endTime$ As String, itemType$ As String, fileName$ As String)

    if not m.playbackLoggingEnabled then return
    
    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" then return

    t$ = chr(9) 
    m.logFile.SendLine("L=p"+t$+"Z="+zoneName$+t$+"S="+startTime$+t$+"E="+endTime$+t$+"I="+itemType$+t$+"N="+fileName$)
    m.logFile.AsyncFlush()

End Sub


Sub WriteEventLogEntry(zoneName$ As String, timestamp$ As String, eventType$ As String, eventData$ As String)

    if not m.eventLoggingEnabled then return

    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" then return

    t$ = chr(9) 
    m.logFile.SendLine("L=e"+t$+"Z="+zoneName$+t$+"T="+timestamp$+t$+"E="+eventType$+t$+"D="+eventData$)
    m.logFile.AsyncFlush()

End Sub


Sub WriteDiagnosticLogEntry(eventId$ As String, eventData$ As String)

    if not m.diagnosticLoggingEnabled then return

    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" then return

    timestamp$ = m.systemTime.GetLocalDateTime().GetString()

    t$ = chr(9) 
    m.logFile.SendLine("L=d"+t$+"T="+timestamp$+t$+"I="+eventId$+t$+"D="+eventData$)
    m.logFile.AsyncFlush()
    
End Sub


Sub PushLogFile()

    if not m.uploadLogsEnabled then return
    
' files that failed to upload in the past were moved to a different folder. move them back to the appropriate folder so that the script can attempt to upload them again
    listOfFailedLogFiles = MatchFiles("/" + m.uploadLogFailedFolder, "*.log")
    for each file in listOfFailedLogFiles
        target$ = m.uploadLogFolder + "/" + file
        fullFilePath$ = m.uploadLogFailedFolder + "/" + file
        ok = MoveFile(fullFilePath$, target$)
    next

    m.networking.UploadLogFiles()
    
End Sub


Sub PushLogFilesOnBoot()

    m.MoveCurrentLog()
    m.PushLogFile()

End Sub


Sub HandleLoggingTimerEvent(msg As Object)

    m.CutoverLogFile()

    m.cutoverTimer.Start()

End Sub


Sub CutoverLogFile()

    if type(m.logFile) <> "roCreateFile" and type(m.logFile) <> "roAppendFile" then return

    m.logFile.Flush()
    m.MoveCurrentLog()
    m.logFile = m.CreateLogFile("ld", "lc")

    m.PushLogFile()
    
End Sub


Sub OpenOrCreateCurrentLog()

' if there is an existing log file for today, just append to it. otherwise, create a new one to use

    listOfPendingLogFiles = MatchFiles("/currentLog", "*")
    
    for each file in listOfPendingLogFiles
        fileName$ = "currentLog/" + file
        m.logFile = CreateObject("roAppendFile", fileName$)
        if type(m.logFile) = "roAppendFile" then
            m.diagnostics.PrintDebug("Use existing log file " + file)
            return
        endif
    next

    m.logFile = m.CreateLogFile("ld", "lc")
    
End Sub


REM *******************************************************
REM *******************************************************
REM ***************                    ********************
REM *************** DIAGNOSTIC CODES   ********************
REM ***************                    ********************
REM *******************************************************
REM *******************************************************

Function newDiagnosticCodes() As Object

    diagnosticCodes = CreateObject("roAssociativeArray")
    
    diagnosticCodes.EVENT_STARTUP                               = "1000"
    diagnosticCodes.EVENT_SYNCSPEC_RECEIVED                     = "1001"
    diagnosticCodes.EVENT_DOWNLOAD_START                        = "1002"
    diagnosticCodes.EVENT_FILE_DOWNLOAD_START                   = "1003"
    diagnosticCodes.EVENT_FILE_DOWNLOAD_COMPLETE                = "1004"
    diagnosticCodes.EVENT_DOWNLOAD_COMPLETE                     = "1005"
    diagnosticCodes.EVENT_READ_SYNCSPEC_FAILURE                 = "1006"
    diagnosticCodes.EVENT_RETRIEVE_SYNCSPEC_FAILURE             = "1007"
    diagnosticCodes.EVENT_NO_SYNCSPEC_AVAILABLE                 = "1008"
    diagnosticCodes.EVENT_SYNCSPEC_DOWNLOAD_IMMEDIATE_FAILURE   = "1009"
    diagnosticCodes.EVENT_FILE_DOWNLOAD_FAILURE                 = "1010"
    diagnosticCodes.EVENT_SYNCSPEC_DOWNLOAD_FAILURE             = "1011"
    diagnosticCodes.EVENT_SYNCPOOL_PROTECT_FAILURE              = "1012"
    diagnosticCodes.EVENT_LOGFILE_UPLOAD_FAILURE                = "1013"
    diagnosticCodes.EVENT_SYNC_ALREADY_ACTIVE                   = "1014"
    diagnosticCodes.EVENT_CHECK_CONTENT                         = "1015"
    diagnosticCodes.EVENT_FILE_DOWNLOAD_PROGRESS                = "1016"
    diagnosticCodes.EVENT_FIRMWARE_DOWNLOAD                     = "1017"
    diagnosticCodes.EVENT_SCRIPT_DOWNLOAD                       = "1018"
	diagnosticCodes.EVENT_REALIZE_FAILURE						= "1032"

    
    return diagnosticCodes
    
End Function


Function StripLeadingSpaces(inputString$ As String) As String

    while true
        if left(inputString$, 1)<>" " then return inputString$
        inputString$ = right(inputString$, len(inputString$)-1)
    endwhile

    return inputString$

End Function


