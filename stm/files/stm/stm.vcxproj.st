<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="12.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|Win32">
      <Configuration>Debug</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
    <ProjectConfiguration Include="Release|Win32">
      <Configuration>Release</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <ProjectGuid>{D9255B56-3FF4-415C-BDE1-F508FE64E385}</ProjectGuid>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'" Label="Configuration">
    <ConfigurationType>Makefile</ConfigurationType>
    <UseDebugLibraries>true</UseDebugLibraries>
    <PlatformToolset>v120</PlatformToolset>
  </PropertyGroup>
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Win32'" Label="Configuration">
    <ConfigurationType>Makefile</ConfigurationType>
    <UseDebugLibraries>false</UseDebugLibraries>
    <PlatformToolset>v120</PlatformToolset>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />
  <ImportGroup Label="ExtensionSettings">
  </ImportGroup>
  <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Release|Win32'">
    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <PropertyGroup Label="UserMacros" />
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
    <NMakeIncludeSearchPath>$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\CoreSupport;$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\DeviceSupport\ST\STM32F10x;$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2\arm-eabi\thumb\cortex_m3;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2\backward;c:\sysgcc\arm-eabi\lib\gcc\arm-eabi\4.9.2\include;c:\sysgcc\arm-eabi\lib\gcc\arm-eabi\4.9.2\include-fixed;c:\sysgcc\arm-eabi\arm-eabi\sys-include;c:\sysgcc\arm-eabi\arm-eabi\include;$(NMakeIncludeSearchPath)</NMakeIncludeSearchPath>
    <NMakeForcedIncludes>$(ProjectDir)\gcc_Debug.h;$(VISUALGDB_DIR)\gcc_compat.h;C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\stm32_compat.h;$(NMakeForcedIncludes)</NMakeForcedIncludes>
    <NMakePreprocessorDefinitions>__VisualGDB_CFG_Debug;$(NMakePreprocessorDefinitions)</NMakePreprocessorDefinitions>
    <NMakeBuildCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /build "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeBuildCommandLine>
    <NMakeCleanCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /clean "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeCleanCommandLine>
    <NMakeReBuildCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /rebuild "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeReBuildCommandLine>
    <NMakeOutput>$(ProjectDir)stm-Debug.vgdbsettings</NMakeOutput>
    <IncludePath />
    <ReferencePath />
    <LibraryPath />
  </PropertyGroup>
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|Win32'">
    <NMakeIncludeSearchPath>$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\CoreSupport;$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\DeviceSupport\ST\STM32F10x;$(LOCALAPPDATA)\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2\arm-eabi\thumb\cortex_m3;c:\sysgcc\arm-eabi\arm-eabi\include\c++\4.9.2\backward;c:\sysgcc\arm-eabi\lib\gcc\arm-eabi\4.9.2\include;c:\sysgcc\arm-eabi\lib\gcc\arm-eabi\4.9.2\include-fixed;c:\sysgcc\arm-eabi\arm-eabi\sys-include;c:\sysgcc\arm-eabi\arm-eabi\include;$(NMakeIncludeSearchPath)</NMakeIncludeSearchPath>
    <NMakeForcedIncludes>$(ProjectDir)\gcc_Release.h;$(VISUALGDB_DIR)\gcc_compat.h;$(NMakeForcedIncludes)</NMakeForcedIncludes>
    <NMakePreprocessorDefinitions>__VisualGDB_CFG_Release;$(NMakePreprocessorDefinitions)</NMakePreprocessorDefinitions>
    <NMakeBuildCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /build "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeBuildCommandLine>
    <NMakeCleanCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /clean "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeCleanCommandLine>
    <NMakeReBuildCommandLine>"$(VISUALGDB_DIR)\VisualGDB.exe" /rebuild "$(ProjectPath)" "/solution:$(SolutionPath)" "/config:$(Configuration)" "/platform:$(Platform)"</NMakeReBuildCommandLine>
    <NMakeOutput>$(ProjectDir)stm-Release.vgdbsettings</NMakeOutput>
    <IncludePath />
    <ReferencePath />
    <LibraryPath />
  </PropertyGroup>
  <ItemDefinitionGroup>
  </ItemDefinitionGroup>
  <ItemGroup>
    <None Include="..\stm32.mak" />
  </ItemGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />
  <ImportGroup Label="ExtensionTargets">
  </ImportGroup>
  <ItemGroup>
    <ClCompile Include="..\main.c" />
    <ClCompile Include="..\misc.c" />
    <ClCompile Include="..\queue.c" />
    <ClCompile Include="..\counter8.c" />
    <ClCompile Include="..\delay.c" />
    <ClCompile Include="..\eeprom.c" />
    <ClCompile Include="..\gps.c" />
    <ClCompile Include="..\gsm.c" />
    <ClCompile Include="..\i8.c" />
    <ClCompile Include="..\ia8.c" />
    <ClCompile Include="..\io16.c" />
    <ClCompile Include="..\o8.c" />
    <ClCompile Include="..\onewire.c" />
    <ClCompile Include="..\plc.c" />
    <ClCompile Include="..\pwm.c" />
    <ClCompile Include="..\pilot_comm.c" />
    <ClCompile Include="..\pilot_usart.c" />
    <ClCompile Include="..\rtc.c" />
    <ClCompile Include="..\slcd.c" />
    <ClCompile Include="..\spi.c" />
    <ClCompile Include="..\test.c" />
    <ClCompile Include="..\usart.c" />
    <ClCompile Include="..\stm32f10x_adc.c" />
    <ClCompile Include="..\stm32f10x_bkp.c" />
    <ClCompile Include="..\stm32f10x_can.c" />
    <ClCompile Include="..\stm32f10x_cec.c" />
    <ClCompile Include="..\stm32f10x_crc.c" />
    <ClCompile Include="..\stm32f10x_dac.c" />
    <ClCompile Include="..\stm32f10x_dbgmcu.c" />
    <ClCompile Include="..\stm32f10x_dma.c" />
    <ClCompile Include="..\stm32f10x_exti.c" />
    <ClCompile Include="..\stm32f10x_flash.c" />
    <ClCompile Include="..\stm32f10x_fsmc.c" />
    <ClCompile Include="..\stm32f10x_gpio.c" />
    <ClCompile Include="..\stm32f10x_i2c.c" />
    <ClCompile Include="..\stm32f10x_it.c" />
    <ClCompile Include="..\stm32f10x_iwdg.c" />
    <ClCompile Include="..\stm32f10x_pwr.c" />
    <ClCompile Include="..\stm32f10x_rcc.c" />
    <ClCompile Include="..\stm32f10x_rtc.c" />
    <ClCompile Include="..\stm32f10x_sdio.c" />
    <ClCompile Include="..\stm32f10x_spi.c" />
    <ClCompile Include="..\stm32f10x_tim.c" />
    <ClCompile Include="..\stm32f10x_usart.c" />
    <ClCompile Include="..\stm32f10x_wwdg.c" />
    <ClCompile Include="..\system_stm32f10x.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\CoreSupport\core_cm3.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\DeviceSupport\ST\STM32F10x\system_stm32f10x.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\Startup\startup_stm32f10x_hd.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\misc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_adc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_bkp.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_can.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_cec.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_crc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_dac.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_dbgmcu.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_dma.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_exti.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_flash.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_fsmc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_gpio.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_i2c.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_iwdg.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_pwr.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_rcc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_rtc.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_sdio.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_spi.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_tim.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_usart.c" />
    <ClCompile Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\src\stm32f10x_wwdg.c" />
  </ItemGroup>
  <ItemGroup>
    <ClInclude Include="..\core_cm3.h" />
    <ClInclude Include="..\core_cmFunc.h" />
    <ClInclude Include="..\core_cmInstr.h" />
    <ClInclude Include="..\misc.h" />
    <ClInclude Include="..\queue.h" />
    <ClInclude Include="..\common_base.h" />
    <ClInclude Include="..\counter8.h" />
    <ClInclude Include="..\delay.h" />
    <ClInclude Include="..\eeprom.h" />
    <ClInclude Include="..\gpio_config.h" />
    <ClInclude Include="..\gps.h" />
    <ClInclude Include="..\gsm.h" />
    <ClInclude Include="..\i8.h" />
    <ClInclude Include="..\ia8.h" />
    <ClInclude Include="..\io16.h" />
    <ClInclude Include="..\io_stm.h" />
    <ClInclude Include="..\it_callback.h" />
    <ClInclude Include="..\o8.h" />
    <ClInclude Include="..\onewire.h" />
    <ClInclude Include="..\plc.h" />
    <ClInclude Include="..\pwm.h" />
    <ClInclude Include="..\pilot_comm.h" />
    <ClInclude Include="..\pilot_usart.h" />
    <ClInclude Include="..\rtc.h" />
    <ClInclude Include="..\slcd.h" />
    <ClInclude Include="..\spi.h" />
    <ClInclude Include="..\stm.h" />
    <ClInclude Include="..\test.h" />
    <ClInclude Include="..\tty_commands.h" />
    <ClInclude Include="..\types.h" />
    <ClInclude Include="..\usart.h" />
    <ClInclude Include="..\stm32f10x.h" />
    <ClInclude Include="..\stm32f10x_adc.h" />
    <ClInclude Include="..\stm32f10x_bkp.h" />
    <ClInclude Include="..\stm32f10x_can.h" />
    <ClInclude Include="..\stm32f10x_cec.h" />
    <ClInclude Include="..\stm32f10x_conf.h" />
    <ClInclude Include="..\stm32f10x_crc.h" />
    <ClInclude Include="..\stm32f10x_dac.h" />
    <ClInclude Include="..\stm32f10x_dbgmcu.h" />
    <ClInclude Include="..\stm32f10x_dma.h" />
    <ClInclude Include="..\stm32f10x_exti.h" />
    <ClInclude Include="..\stm32f10x_flash.h" />
    <ClInclude Include="..\stm32f10x_fsmc.h" />
    <ClInclude Include="..\stm32f10x_gpio.h" />
    <ClInclude Include="..\stm32f10x_i2c.h" />
    <ClInclude Include="..\stm32f10x_it.h" />
    <ClInclude Include="..\stm32f10x_iwdg.h" />
    <ClInclude Include="..\stm32f10x_pwr.h" />
    <ClInclude Include="..\stm32f10x_rcc.h" />
    <ClInclude Include="..\stm32f10x_rtc.h" />
    <ClInclude Include="..\stm32f10x_sdio.h" />
    <ClInclude Include="..\stm32f10x_spi.h" />
    <ClInclude Include="..\stm32f10x_tim.h" />
    <ClInclude Include="..\stm32f10x_type.h" />
    <ClInclude Include="..\stm32f10x_usart.h" />
    <ClInclude Include="..\stm32f10x_wwdg.h" />
    <ClInclude Include="..\stm32_conf.h" />
    <ClInclude Include="..\system_stm32f10x.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\CoreSupport\core_cm3.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\DeviceSupport\ST\STM32F10x\stm32f10x.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\CMSIS\CM3\DeviceSupport\ST\STM32F10x\system_stm32f10x.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\misc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_adc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_bkp.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_can.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_cec.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_crc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_dac.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_dbgmcu.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_dma.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_exti.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_flash.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_fsmc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_gpio.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_i2c.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_iwdg.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_pwr.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_rcc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_rtc.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_sdio.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_spi.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_tim.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_usart.h" />
    <ClInclude Include="C:\Users\amd\AppData\Local\VisualGDB\EmbeddedBSPs\arm-eabi\com.sysprogs.arm.stm32\STM32F1xxxx\STM32F10x_StdPeriph_Driver\inc\stm32f10x_wwdg.h" />
  </ItemGroup>
</Project>