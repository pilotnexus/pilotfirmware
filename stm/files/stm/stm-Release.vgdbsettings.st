<?xml version="1.0"?>
<VisualGDBProjectSettings2 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ConfigurationName>Release</ConfigurationName>
  <Project xsi:type="com.visualgdb.project.embedded">
    <CustomSourceDirectories>
      <Directories />
      <PathStyle>MinGWUnixSlash</PathStyle>
    </CustomSourceDirectories>
    <MainSourceDirectory>D:\Source\RPCP\build\rpcpbuilder\bin\Debug\out\stm</MainSourceDirectory>
    <EmbeddedProfileFile>stm32.xml</EmbeddedProfileFile>
    <ExcludeToolDirsFromMakeFiles>false</ExcludeToolDirsFromMakeFiles>
  </Project>
  <Build xsi:type="com.visualgdb.build.custom">
    <BuildCommand>
      <SkipWhenRunningCommandList>false</SkipWhenRunningCommandList>
      <Command>build_deploy.bat</Command>
      <Arguments />
      <WorkingDirectory>D:\Source\RPCP\build\rpcpbuilder\bin\Debug\out\stm</WorkingDirectory>
      <Environment>
        <Records>
          <Record>
            <VariableName>LANG</VariableName>
            <Value>en_US.UTF-8</Value>
          </Record>
          <Record>
            <VariableName>PATH</VariableName>
            <Value>%PATH%;C:\SysGCC\arm-eabi\bin</Value>
          </Record>
        </Records>
      </Environment>
    </BuildCommand>
    <CleanCommand>
      <SkipWhenRunningCommandList>false</SkipWhenRunningCommandList>
      <Command>cmd.exe</Command>
      <Arguments>/c "C:\SysGCC\arm-eabi\bin\make.exe" clean</Arguments>
      <WorkingDirectory>$(BuildDir)</WorkingDirectory>
      <Environment>
        <Records>
          <Record>
            <VariableName>LANG</VariableName>
            <Value>en_US.UTF-8</Value>
          </Record>
          <Record>
            <VariableName>PATH</VariableName>
            <Value>%PATH%;C:\SysGCC\arm-eabi\bin</Value>
          </Record>
        </Records>
      </Environment>
    </CleanCommand>
    <MainBuildDirectory>D:\Source\RPCP\build\rpcpbuilder\bin\Debug\out\stm</MainBuildDirectory>
    <AbsoluteTargetPath>D:\Source\RPCP\build\rpcpbuilder\bin\Debug\out\stm\stm.bin</AbsoluteTargetPath>
    <AutoUpdateMakefiles>true</AutoUpdateMakefiles>
  </Build>
  <Debug xsi:type="com.visualgdb.debug.embedded">
    <AdditionalStartupCommands />
    <AdditionalGDBSettings>
      <FilterSpuriousStoppedNotifications>false</FilterSpuriousStoppedNotifications>
      <ForceSingleThreadedMode>false</ForceSingleThreadedMode>
      <PendingBreakpointsSupported>true</PendingBreakpointsSupported>
      <DisableChildRanges>false</DisableChildRanges>
      <UseAppleExtensions>false</UseAppleExtensions>
      <CanAcceptCommandsWhileRunning>false</CanAcceptCommandsWhileRunning>
      <MakeLogFile>false</MakeLogFile>
      <IgnoreModuleEventsWhileStepping>true</IgnoreModuleEventsWhileStepping>
      <UseRelativePathsOnly>false</UseRelativePathsOnly>
      <ExitAction>None</ExitAction>
      <Features>
        <DisableAutoDetection>false</DisableAutoDetection>
        <UseFrameParameter>false</UseFrameParameter>
        <SimpleValuesFlagSupported>false</SimpleValuesFlagSupported>
        <ListLocalsSupported>false</ListLocalsSupported>
        <ByteLevelMemoryCommandsAvailable>false</ByteLevelMemoryCommandsAvailable>
        <ThreadInfoSupported>false</ThreadInfoSupported>
        <PendingBreakpointsSupported>false</PendingBreakpointsSupported>
        <SupportTargetCommand>false</SupportTargetCommand>
      </Features>
      <DisableDisassembly>false</DisableDisassembly>
      <ExamineMemoryWithXCommand>false</ExamineMemoryWithXCommand>
      <StepIntoNewInstanceEntry>main</StepIntoNewInstanceEntry>
      <ExamineRegistersInRawFormat>true</ExamineRegistersInRawFormat>
      <EnableSmartStepping>false</EnableSmartStepping>
      <DisableSignals>false</DisableSignals>
      <EnableAsyncExecutionMode>false</EnableAsyncExecutionMode>
      <EnableNonStopMode>false</EnableNonStopMode>
    </AdditionalGDBSettings>
    <DebugMethodID>com.visualgdb.customstub</DebugMethodID>
    <DebugMethodProperties>
      <Entries>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubEXE</Key>
          <Value />
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubArgs</Key>
          <Value />
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubDir</Key>
          <Value />
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubEnv</Key>
          <Value />
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubPort</Key>
          <Value>2331</Value>
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubStartupDelay</Key>
          <Value>0</Value>
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubEraseCmd</Key>
          <Value />
        </KeyValue>
        <KeyValue>
          <Key>com.visualgdb.dbgfallback.GDBStubProgramCmd</Key>
          <Value />
        </KeyValue>
      </Entries>
    </DebugMethodProperties>
    <SemihostingSupport>Auto</SemihostingSupport>
    <StepIntoEntryPoint>false</StepIntoEntryPoint>
    <ReloadFirmwareOnReset>false</ReloadFirmwareOnReset>
  </Debug>
  <CustomBuild>
    <PreBuildActions />
    <PostBuildActions />
    <PreCleanActions />
    <PostCleanActions />
  </CustomBuild>
  <CustomDebug>
    <PreDebugActions />
    <PostDebugActions />
    <BreakMode>Default</BreakMode>
  </CustomDebug>
  <CustomShortcuts>
    <Shortcuts />
    <ShowMessageAfterExecuting>true</ShowMessageAfterExecuting>
  </CustomShortcuts>
  <UserDefinedVariables />
</VisualGDBProjectSettings2>