#Requires AutoHotkey v2.0
#SingleInstance Force

global sendDelay := 125       ; Base per-character input speed, in milliseconds
global randomFactor := 1     ; Default random fluctuation +/-100%
global isRandomEnabled := true
global isGuiVisible := true
global isMButtonEnabled := true  ; Initial state: Enable MButton hotkey
global customText := ""      ; Custom input text for Alt+S
global customText2 := ""     ; Custom input text for Alt+X
global isCustomHidden := false ; Custom text (Alt+S) visibility state
global isCustomHidden2 := false ; Custom text (Alt+X) visibility state
global isBackspaceEnabled := false ; Backspace simulation enabled
global backspaceChance := 2  ; Backspace probability (0–100%)
global backspaceDelay := 100  ; Delay before backspace, in milliseconds
global backspaceRetypeDelay := 300 ; Delay before retyping after backspace, in milliseconds
global sendText1 := ""        ; Text to send via timer
global sendIndex := 0       ; Current character index for timer-based sending
global hasBackspaced := false ; Flag to limit backspace to once per input
global wordList := []        ; Array of words from txt file
global wordIndex := 1        ; Current word index for Alt+4
global wordFilePath := ""    ; Path to txt file for Alt+4
global lastActiveWindow := 0 ; 
global quickGuiWidth1 := 326, quickGuiWidth2 := 390
global quickGuiExpandedWidth3 := 330, quickGuiExpandedWidth4 := 550
global isQuickGuiExpanded := false


; Define all callback functions
ToggleMButton(GuiCtrlObj, Info) {
    global isMButtonEnabled := GuiCtrlObj.Value
    SaveSettings()
}

ToggleRandom(GuiCtrlObj, Info) {
    global isRandomEnabled := GuiCtrlObj.Value
    SaveSettings()
}

ToggleBackspace(GuiCtrlObj, Info) {
    global isBackspaceEnabled := GuiCtrlObj.Value
    SaveSettings()
}

UpdateRandomFactor(GuiCtrlObj, Info) {
    global randomFactor
    val := GuiCtrlObj.Text
    if (val = "" or !IsNumber(val)) {
        randomFactor := 1
        GuiCtrlObj.Text := "1"
    } else {
        randomFactor := Max(0, Min(val, 100)) ; Limit to 0–100%
    }
    SaveSettings()
}

UpdateBackspaceChance(GuiCtrlObj, Info) {
    global backspaceChance
    val := GuiCtrlObj.Text
    if (val = "" or !IsNumber(val)) {
        backspaceChance := 10
        GuiCtrlObj.Text := "10"
    } else {
        backspaceChance := Max(0, Min(val, 100)) ; Limit to 0–100%
    }
    SaveSettings()
}

UpdateBackspaceDelay(GuiCtrlObj, Info) {
    global backspaceDelay
    val := GuiCtrlObj.Text
    if (val = "" or !IsNumber(val)) {
        backspaceDelay := 100
        GuiCtrlObj.Text := "100"
    } else {
        backspaceDelay := Max(50, Min(val, 1000)) ; Limit to 50–1000ms
    }
    SaveSettings()
}

UpdateBackspaceRetypeDelay(GuiCtrlObj, Info) {
    global backspaceRetypeDelay
    val := GuiCtrlObj.Text
    if (val = "" or !IsNumber(val)) {
        backspaceRetypeDelay := 100
        GuiCtrlObj.Text := "100"
    } else {
        backspaceRetypeDelay := Max(50, Min(val, 1000)) ; Limit to 50–1000ms
    }
    SaveSettings()
}

UpdateCustomText(GuiCtrlObj, Info) {
    global customText := GuiCtrlObj.Text
    SaveSettings()
}

UpdateCustomText2(GuiCtrlObj, Info) {
    global customText2 := GuiCtrlObj.Text
    SaveSettings()
}

SelectWordFile(*) {
    global wordFilePath, WordFileEdit, wordList, wordIndex
    selectedFile := FileSelect(3, A_WorkingDir, "Select a text file", "Text Files (*.txt)")
    if (selectedFile = "") {
        return
    }
    wordFilePath := selectedFile
    WordFileEdit.Text := wordFilePath
    wordList := LoadWordList(wordFilePath)
    wordIndex := 1
    SaveSettings()
}

ToggleCustomVisibility(*) {
    global isCustomHidden, CustomInputEdit, ToggleVisibilityButton
    isCustomHidden := !isCustomHidden
    CustomInputEdit.Opt(isCustomHidden ? "+Password" : "-Password")
    ToggleVisibilityButton.Text := isCustomHidden ? "隐藏" : "显示"
    SaveSettings()
}

ToggleCustomVisibility2(*) {
    global isCustomHidden2, CustomInputEdit2, ToggleVisibilityButton2
    isCustomHidden2 := !isCustomHidden2
    CustomInputEdit2.Opt(isCustomHidden2 ? "+Password" : "-Password")
    ToggleVisibilityButton2.Text := isCustomHidden2 ? "隐藏" : "显示"
    SaveSettings()
}

Button0_Click(*) {
    tutorialText := "
    (
【随机输入模拟器简明指南】

1. 打开软件
- 双击启动，主窗口即控制面板。
- 按 Alt+0 可随时显示/隐藏主窗口。

2. 主窗口功能
- 输入速度：四档可选，或自定义毫秒数，按钮变绿为选中。
- 鼠标中键热键：勾选后可用中键快速输入随机数字。
- 随机波动：勾选后每字间隔有随机变化，范围可调。
- 回退模拟：勾选后偶尔模拟打错重打，概率和延迟可调。
- 自定义输入 (Alt+S/X)：可保存常用短语，支持隐藏显示。
- 单词输入 (Alt+4)：导入txt文件，每次发送下一个单词。
- 快捷操作面板：更多按钮，点“★打开快捷操作面板”弹出。

3. 常用热键（无需打开主窗口）
- Alt+1：输入“0.000”+随机数字
- Alt+2：输入“0.0000”+随机数字
- Alt+3：输入随机字母数字串
- Alt+4：发送下一个单词（需导入文件）
- Alt+S/X：发送自定义短语
- 鼠标中键：同 Alt+1（需启用）
- Alt+0：显示/隐藏主窗口

4. 快捷操作面板
- 顶部大按钮：快速输入随机数、字符、单词
- 中间小按钮：26字母键盘、复制、粘贴、截图、全选、自定义短语
- 数字键盘：1-9、0、小数点、删除、回车

5. 小提示
- 建议先在记事本测试。
- 输入异常请检查焦点。
- 设置自动保存，重置请删除 AppData\RandomInputSimulator\settings.ini。
-----------------------------------------------------------------------
【注意】本软件仅供学习交流使用，请勿用于任何违法活动。
反馈建议：asywish1@gmail.com
    )"
    MsgBox tutorialText, "使用教程"
}

ButtonA_Click(*) {
    global sendDelay, myGui, ButtonA, ButtonB, ButtonC, ButtonD
    sendDelay := 50
    myGui["MyText"].Text := "目前逐字输入速度延迟为: " . sendDelay . "ms"
    HighlightButton(ButtonA)
    SaveSettings()
}

ButtonB_Click(*) {
    global sendDelay, myGui, ButtonA, ButtonB, ButtonC, ButtonD
    sendDelay := 75
    myGui["MyText"].Text := "目前逐字输入速度延迟为: " . sendDelay . "ms"
    HighlightButton(ButtonB)
    SaveSettings()
}

ButtonC_Click(*) {
    global sendDelay, myGui, ButtonA, ButtonB, ButtonC, ButtonD
    sendDelay := 100
    myGui["MyText"].Text := "目前逐字输入速度延迟为: " . sendDelay . "ms"
    HighlightButton(ButtonC)
    SaveSettings()
}

ButtonD_Click(*) {
    global sendDelay, myGui, ButtonA, ButtonB, ButtonC, ButtonD
    sendDelay := 125
    myGui["MyText"].Text := "目前逐字输入速度延迟为: " . sendDelay . "ms"
    HighlightButton(ButtonD)
    SaveSettings()
}

ApplyCustomDelay(*) {
    global sendDelay, myGui, CustomDelayEdit, ButtonA, ButtonB, ButtonC, ButtonD
    val := CustomDelayEdit.Text
    if (val = "" or !IsNumber(val) or val <= 0) {
        MsgBox "请输入有效的正整数！", "错误"
        return
    }
    sendDelay := Min(val, 1000)  ; Limit to max 1000ms
    CustomDelayEdit.Text := sendDelay
    myGui["MyText"].Text := "目前逐字输入速度延迟为: " . sendDelay . "ms"
    HighlightButton("")  ; Reset highlights
    SaveSettings()
}

HighlightButton(clickedButton) {
    ; Reset all buttons
    ButtonA.Opt("BackgroundDefault")
    ButtonB.Opt("BackgroundDefault")
    ButtonC.Opt("BackgroundDefault")
    ButtonD.Opt("BackgroundDefault")
    
    if (clickedButton != "") {
        clickedButton.Opt("BackgroundC0FFC0")  ; Light green highlight
    }
}

; Load settings
LoadSettings()

; Create GUI interface
myGui := Gui()
myGui.Opt("+LastFound +Resize +Theme")
myGui.BackColor := "F0F0F0"
myGui.SetFont("s10", "Segoe UI")
myGui.Title := "随机输入模拟器"

; Input speed settings group
myGui.Add("GroupBox", "w280 h220 Section", "输入速度设置")
myGui.Add("Text", "vMyText xs+10 ys+20 w250", "目前逐字输入速度延迟为: " . sendDelay . "ms")
global ButtonA := myGui.Add("Button", "xs+10 ys+45 w125", "快速50ms")
ButtonA.OnEvent("Click", ButtonA_Click)
global ButtonB := myGui.Add("Button", "x+5 yp w125", "中速75ms")
ButtonB.OnEvent("Click", ButtonB_Click)
global ButtonC := myGui.Add("Button", "xs+10 y+10 w125", "慢速100ms")
ButtonC.OnEvent("Click", ButtonC_Click)
global ButtonD := myGui.Add("Button", "x+5 yp w125", "【推荐】125ms")
ButtonD.OnEvent("Click", ButtonD_Click)
myGui.Add("Text", "xs+10 y+10 w250", "自定义延迟 (ms):")
global CustomDelayEdit := myGui.Add("Edit", "xs+10 y+10 w125 Number", "")
myGui.Add("Button", "x+5 yp w125", "应用").OnEvent("Click", ApplyCustomDelay)
myGui.Add("Button", "xs+10 y+10 w250", "【★必看】使用教程").OnEvent("Click", Button0_Click)

; 在GUI创建部分添加新按钮（在原GUI的合适位置，例如单词输入设置组之后）
myGui.Add("Button", "xs+10 y+10 w250", "★打开快捷操作面板").OnEvent("Click", OpenQuickPanel)

switch sendDelay {
    case 50: HighlightButton(ButtonA)
    case 75: HighlightButton(ButtonB)
    case 100: HighlightButton(ButtonC)
    case 125: HighlightButton(ButtonD)
    default: HighlightButton("")
}

; Mouse middle button toggle
mbuttonOpts := "vMButtonToggle xs+10 y+10 w250 " . (isMButtonEnabled ? "Checked" : "")
myGui.Add("CheckBox", mbuttonOpts, "启用 鼠标中键 热键").OnEvent("Click", ToggleMButton)

; Random fluctuation settings group
myGui.Add("GroupBox", "w280 h120 xm Section", "随机波动设置")
randomOpts := "vRandomToggle xs+10 ys+20 w250 " . (isRandomEnabled ? "Checked" : "")
myGui.Add("CheckBox", randomOpts, "启用随机波动").OnEvent("Click", ToggleRandom)
myGui.Add("Text", "xs+10 y+10", "随机波动范围 (+/-%):")
global RandomInputEdit := myGui.Add("Edit", "xs+10 y+10 w100", randomFactor)
RandomInputEdit.OnEvent("Change", UpdateRandomFactor)
global RandomUpDown := myGui.Add("UpDown", "vRandomUpDown Range0-1000", randomFactor)
RandomUpDown.OnEvent("Change", UpdateRandomFactorFromUpDown)

; Backspace simulation settings group
myGui.Add("GroupBox", "w280 h160 xm Section", "回退模拟设置")
backspaceOpts := "vBackspaceToggle xs+10 ys+20 w250 " . (isBackspaceEnabled ? "Checked" : "")
myGui.Add("CheckBox", backspaceOpts, "启用随机回退 (仅Alt+1/2/3/4和鼠标中键)").OnEvent("Click", ToggleBackspace)
myGui.Add("Text", "xs+10 y+10", "回退的概率 (%):")
BackspaceInputEdit := myGui.Add("Edit", "x+5 yp w100 Number", backspaceChance)
BackspaceInputEdit.OnEvent("Change", UpdateBackspaceChance)
myGui.Add("Text", "xs+10 y+10", "回退前延迟 (ms):")
BackspaceDelayEdit := myGui.Add("Edit", "x+5 yp w100 Number", backspaceDelay)
BackspaceDelayEdit.OnEvent("Change", UpdateBackspaceDelay)
myGui.Add("Text", "xs+10 y+10", "纠正后延迟 (ms):")
BackspaceRetypeDelayEdit := myGui.Add("Edit", "x+5 yp w100 Number", backspaceRetypeDelay)
BackspaceRetypeDelayEdit.OnEvent("Change", UpdateBackspaceRetypeDelay)

; Custom input settings group (Alt+S)
myGui.Add("GroupBox", "w280 h100 xm Section", "自定义输入设置 (Alt+S)")
opts := "xs+10 ys+20 w150"
if isCustomHidden
    opts .= " Password"
global CustomInputEdit := myGui.Add("Edit", opts, customText)
CustomInputEdit.OnEvent("Change", UpdateCustomText)
global ToggleVisibilityButton := myGui.Add("Button", "x+5 yp w100", isCustomHidden ? "隐藏" : "显示")
ToggleVisibilityButton.OnEvent("Click", ToggleCustomVisibility)

; Second custom input settings group (Alt+X)
myGui.Add("GroupBox", "w280 h100 xm Section", "自定义输入设置 (Alt+X)")
opts2 := "xs+10 ys+20 w150"
if isCustomHidden2
    opts2 .= " Password"
global CustomInputEdit2 := myGui.Add("Edit", opts2, customText2)
CustomInputEdit2.OnEvent("Change", UpdateCustomText2)
global ToggleVisibilityButton2 := myGui.Add("Button", "x+5 yp w100", isCustomHidden2 ? "隐藏" : "显示")
ToggleVisibilityButton2.OnEvent("Click", ToggleCustomVisibility2)

; Word input settings group (Alt+4)
myGui.Add("GroupBox", "w280 h80 xm Section", "单词输入设置 (Alt+4)")
myGui.Add("Text", "xs+10 ys+20 w250", "单词文件 (Alt+4):")
global WordFileEdit := myGui.Add("Edit", "xs+10 y+10 w150", wordFilePath)
myGui.Add("Button", "x+5 yp w100", "浏览").OnEvent("Click", SelectWordFile)

myGui.Show("AutoSize")
DllCall("user32.dll\SetLayeredWindowAttributes", "Ptr", WinExist(), "UInt", 0, "UChar", 220, "UInt", 1)

; Hotkeys
!0::ToggleGui()  ; Alt+0: Show/hide GUI
!s::sendCustom(customText)  ; Alt+S: Send first custom text
!x::sendCustom(customText2) ; Alt+X: Send second custom text
!4::SendNextWord()          ; Alt+4: Send next word from list

; Hide/show GUI
ToggleGui() {
    global isGuiVisible, myGui
    if (isGuiVisible) {
        myGui.Hide()
        isGuiVisible := false
    } else {
        myGui.Show()
        isGuiVisible := true
    }
}

; Optimized timer-based sendSlowly function with backspace simulation
sendSlowly(text, delayMs?) {
    global sendText1, sendIndex, sendDelay, randomFactor, isRandomEnabled, isBackspaceEnabled, backspaceChance, backspaceDelay, backspaceRetypeDelay, hasBackspaced
    if !IsSet(delayMs)
        delayMs := sendDelay
    sendText1 := text
    sendIndex := 1
    hasBackspaced := false  ; Reset backspace flag
    SetTimer(SendChar, -1)  ; Start immediately
    return

    SendChar() {
        global sendText1, sendIndex, sendDelay, randomFactor, isRandomEnabled, isBackspaceEnabled, backspaceChance, backspaceDelay, backspaceRetypeDelay, hasBackspaced
        if (sendIndex > StrLen(sendText1)) {
            SetTimer( , 0)  ; Stop timer
            return
        }
        char := SubStr(sendText1, sendIndex, 1)
        SendInput("{Text}" . char)
        ; Simulate backspace once if enabled and not yet backspaced
        if (isBackspaceEnabled && !hasBackspaced && Random(0, 99) < backspaceChance) {
            Sleep backspaceDelay  ; Configurable delay before backspace
            SendInput("{Backspace}")
            Sleep backspaceRetypeDelay  ; Configurable delay before retyping
            SendInput("{Text}" . char)
            hasBackspaced := true  ; Prevent further backspaces
        }
        sendIndex++
        delay := isRandomEnabled ? delayMs * (1 + (Random(-randomFactor * 100, randomFactor * 100) / 100)) : delayMs
        SetTimer( , -Round(delay))  ; Schedule next character
    }
}

; Custom input function (fixed 50ms, no random fluctuation or backspace)
sendCustom(text) {
    for char in StrSplit(text) {
        SendInput("{Text}" . char)
        Sleep 50
    }
}

; Send next word from wordList for Alt+4
SendNextWord() {
    global wordList, wordIndex
    if (wordList.Length = 0) {
        MsgBox "请先选择一个包含单词的文本文件！", "错误"
        return
    }
    if (wordIndex > wordList.Length) {
        wordIndex := 1  ; Loop back to start
    }
    sendSlowly(wordList[wordIndex])
    wordIndex++
    SaveSettings()  ; Save the updated index
}

; Load word list from txt file
LoadWordList(filePath) {
    global wordList
    wordList := []
    if !FileExist(filePath) {
        MsgBox "文件不存在: " . filePath, "错误"
        return wordList
    }
    try {
        content := FileRead(filePath)
        for line in StrSplit(content, "`n", "`r") {
            trimmed := Trim(line)
            if (trimmed != "") {
                wordList.Push(trimmed)
            }
        }
    } catch as err {
        MsgBox "读取文件失败: " . err.Message, "错误"
        return wordList
    }
    return wordList
}

; Generate random digit string
generateRandomDigits(minLen := 4, maxLen := 7) {
    len := Random(minLen, maxLen)
    str := ""
    loop len {
        str .= Random(0, 9)
    }
    return str
}

; Hotkeys for random text
!1::sendSlowly("0.000" generateRandomDigits())  ; Alt+1: 0.000 + digits
!2::sendSlowly("0.0000" generateRandomDigits()) ; Alt+2: 0.0000 + digits
~MButton:: {
    if (isMButtonEnabled) {
        sendSlowly("0.000" generateRandomDigits())
    }
}
!3::sendSlowly(generateRandomString())  ; Alt+3: Random string

generateRandomString() {
    chars := "abcdefghijklmnopqrstuvwxyz0123456789"
    str := ""
    length := Random(5, 10)
    Loop length {
        index := Random(1, StrLen(chars))
        str .= SubStr(chars, index, 1)
    }
    return str
}

; Load settings from AppData
LoadSettings() {
    appDataPath := A_AppData "\RandomInputSimulator"
    iniFile := appDataPath "\settings.ini"
    if !FileExist(appDataPath) {
        DirCreate appDataPath  ; Create directory if it doesn't exist
    }
    if !FileExist(iniFile)
        return
    global sendDelay := IniRead(iniFile, "Settings", "sendDelay", 75)
   global randomFactor := IniRead(iniFile, "Settings", "randomFactor", "1.0") + 0.0  ; 确保读取为数字
    global isRandomEnabled := IniRead(iniFile, "Settings", "isRandomEnabled", 1)
    global isMButtonEnabled := IniRead(iniFile, "Settings", "isMButtonEnabled", 1)
    global customText := IniRead(iniFile, "Settings", "customText", "")
    global isCustomHidden := IniRead(iniFile, "Settings", "isCustomHidden", 0)
    global customText2 := IniRead(iniFile, "Settings", "customText2", "")
    global isCustomHidden2 := IniRead(iniFile, "Settings", "isCustomHidden2", 0)
    global isBackspaceEnabled := IniRead(iniFile, "Settings", "isBackspaceEnabled", 0)
    global backspaceChance := IniRead(iniFile, "Settings", "backspaceChance", 10)
    global backspaceDelay := IniRead(iniFile, "Settings", "backspaceDelay", 100)
    global backspaceRetypeDelay := IniRead(iniFile, "Settings", "backspaceRetypeDelay", 100)
    global wordFilePath := IniRead(iniFile, "Settings", "wordFilePath", "")
    global wordIndex := IniRead(iniFile, "Settings", "wordIndex", 1)
    if (wordFilePath != "") {
        global wordList := LoadWordList(wordFilePath)
        if (wordList.Length > 0 && (wordIndex > wordList.Length || wordIndex < 1)) {
            wordIndex := 1
        }
    }
}

; Save settings to AppData
SaveSettings() {
    appDataPath := A_AppData "\RandomInputSimulator"
    iniFile := appDataPath "\settings.ini"
    if !FileExist(appDataPath) {
        DirCreate appDataPath  ; Create directory if it doesn't exist
    }
    IniWrite sendDelay, iniFile, "Settings", "sendDelay"
    IniWrite Format("{:.1f}", randomFactor), iniFile, "Settings", "randomFactor"  ; 保存为小数点格式
    IniWrite isRandomEnabled ? 1 : 0, iniFile, "Settings", "isRandomEnabled"
    IniWrite isMButtonEnabled ? 1 : 0, iniFile, "Settings", "isMButtonEnabled"
    IniWrite customText, iniFile, "Settings", "customText"
    IniWrite isCustomHidden ? 1 : 0, iniFile, "Settings", "isCustomHidden"
    IniWrite customText2, iniFile, "Settings", "customText2"
    IniWrite isCustomHidden2 ? 1 : 0, iniFile, "Settings", "isCustomHidden2"
    IniWrite isBackspaceEnabled ? 1 : 0, iniFile, "Settings", "isBackspaceEnabled"
    IniWrite backspaceChance, iniFile, "Settings", "backspaceChance"
    IniWrite backspaceDelay, iniFile, "Settings", "backspaceDelay"
    IniWrite backspaceRetypeDelay, iniFile, "Settings", "backspaceRetypeDelay"
    IniWrite wordFilePath, iniFile, "Settings", "wordFilePath"
    IniWrite wordIndex, iniFile, "Settings", "wordIndex"
}

; Add new functions
UpdateRandomFactor1(GuiCtrlObj, Info) {
    global randomFactor, RandomInputEdit, RandomUpDown
    val := GuiCtrlObj.Text
    if (val = "" or !RegExMatch(val, "^\d*\.?\d+$")) {
        randomFactor := 1
        RandomInputEdit.Text := "1"
    } else {
        randomFactor := Max(0, Min(val + 0, 100))
    }
    RandomUpDown.Value := randomFactor
    SaveSettings()
}

UpdateRandomFactorFromUpDown(GuiCtrlObj, Info) {
    global randomFactor, RandomInputEdit
    randomFactor := GuiCtrlObj.Value
    RandomInputEdit.Text := randomFactor
    SaveSettings()
}

; 复制粘贴功能
; Function to simulate copy operation
CopySelection() {
    ; Send Ctrl+C to copy the selected text/content to the clipboard
    SendInput "{Ctrl down}"
    Sleep 1
    SendInput "{c down}"
    Sleep 1
    SendInput "{c up}"
    Sleep 1
    SendInput "{Ctrl up}"
    Sleep 10  ; Brief delay to ensure clipboard operation completes
}

; Function to simulate paste operation
PasteClipboard() {
    ; Send Ctrl+V to paste the clipboard content
    SendInput "{Ctrl down}"
    Sleep 1
    SendInput "{v down}"
    Sleep 1
    SendInput "{v up}"
    Sleep 1
    SendInput "{Ctrl up}"
    Sleep 10  ; Brief delay to ensure paste operation completes
}

;全选
CtrlA() {
    ; Send Ctrl+a to copy the selected text/content to the clipboard
    SendInput "{Ctrl down}"
    Sleep 1
    SendInput "{a down}"
    Sleep 1
    SendInput "{a up}"
    Sleep 1
    SendInput "{Ctrl up}"
    Sleep 10  ; Brief delay to ensure clipboard operation completes
}

;微信截图
AltA() {
    ; Send Ctrl+a to copy the selected text/content to the clipboard
    SendInput "{Alt down}"
    Sleep 1
    SendInput "{a down}"
    Sleep 1
    SendInput "{a up}"
    Sleep 1
    SendInput "{Alt up}"
    Sleep 10  ; Brief delay to ensure clipboard operation completes
}

; 修改 OpenQuickPanel 函数
OpenQuickPanel(*) {
    global quickGui, quickGuiWidth1, quickGuiWidth2, lastFocusedControl, myGui
    ; 保存当前焦点的控件（仅用于主 GUI 关闭面板后恢复）
    lastFocusedControl := ControlGetFocus("ahk_id " . myGui.Hwnd)
    quickGui := Gui("+AlwaysOnTop +ToolWindow +E0x08000000", "快捷操作面板")
    quickGui.SetFont("s10", "Segoe UI")

    global lastFocusedControl, myGui
    ; 保存当前焦点的控件（仅用于主 GUI 关闭面板后恢复）
    lastFocusedControl := ControlGetFocus("ahk_id " . myGui.Hwnd)
    quickGui := Gui("+AlwaysOnTop +ToolWindow +E0x08000000", "快捷操作面板")  ; 防止点击时转移焦点
    quickGui.SetFont("s10", "Segoe UI")
    
    ; 三横向按钮（顶部三行）
    quickGui.SetFont("s10 Bold", "Segoe UI")  ; 设置字体
    quickGui.Add("Button", "w300 h40 x10 y10", "Alt + 1【0.000】").OnEvent("Click", (*) => sendSlowly("0.000" generateRandomDigits()))
    quickGui.Add("Button", "w300 h40 x10 y+5", "Alt + 3【随机字符】").OnEvent("Click", (*) => sendSlowly(generateRandomString()))
    quickGui.Add("Button", "w300 h40 x10 y+5", "Alt + 4【导入文本输出】").OnEvent("Click", (*) => SendNextWord() )
    
    ; 四小按钮（两行两列）
    quickGui.Add("Button", "w89 h40 x10 y+5", "26键").OnEvent("Click", (*) => TogglequickGuiWidth2())
    quickGui.Add("Button", "w89 h40 x+14 yp", "自定义一").OnEvent("Click", (*) => sendCustom(customText))
    quickGui.Add("Button", "w89 h40 x+14.3 yp", "自定义二").OnEvent("Click", (*) => sendCustom(customText2))
    quickGui.Add("Button", "w89 h40 x10 y+5", "截图").OnEvent("Click", (*) => sendSlowly(AltA()))
    quickGui.Add("Button", "w89 h40 x+14 yp", "复制").OnEvent("Click", (*) => sendSlowly(CopySelection()))
    quickGui.Add("Button", "w89 h40 x+14.3 yp", "粘贴").OnEvent("Click", (*) => sendSlowly(PasteClipboard()))

    ; 第一行按钮
    quickGui.Add("Button", "w45 h40 x10 y+10", "1").OnEvent("Click", (*) => Send("1"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "2").OnEvent("Click", (*) => Send("2"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "3").OnEvent("Click", (*) => Send("3"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "4").OnEvent("Click", (*) => Send("4"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "5").OnEvent("Click", (*) => Send("5"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "6").OnEvent("Click", (*) => Send("6"))
    

    ; 第二行按钮
    quickGui.Add("Button", "w45 h40 x10 y+10", "7").OnEvent("Click", (*) => Send("7"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "8").OnEvent("Click", (*) => Send("8"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "9").OnEvent("Click", (*) => Send("9"))
    quickGui.Add("Button", "w45 h40 x+5 yp", "全").OnEvent("Click", (*) => sendSlowly(CtrlA()))
    quickGui.Add("Button", "w45 h40 x+5 yp", "0").OnEvent("Click", (*) => Send("0"))
    quickGui.Add("Button", "w45 h40 x+5 yp", ".").OnEvent("Click", (*) => Send("."))


    ; 第三行按钮 (删除和回车)
    quickGui.Add("Button", "w140 h40 x10 y+10", "删除").OnEvent("Click", (*) => Send("{Backspace}"))
    quickGui.Add("Button", "w140 h40 x+18 yp", "确认/回车").OnEvent("Click", (*) => Send("{Enter}"))



    quickGui.OnEvent("Close", RestoreFocus)
    quickGui.Show("w" . quickGuiWidth1-8 . " h" . quickGuiWidth2)  ; 使用变量
    ; 26键位
    quickGui.Add("Button", "w25 h30 x10 y+10", "q").OnEvent("Click", (*) => Send("q"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "w").OnEvent("Click", (*) => Send("w"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "e").OnEvent("Click", (*) => Send("e"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "r").OnEvent("Click", (*) => Send("r"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "t").OnEvent("Click", (*) => Send("t"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "y").OnEvent("Click", (*) => Send("y"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "u").OnEvent("Click", (*) => Send("u"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "i").OnEvent("Click", (*) => Send("i"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "o").OnEvent("Click", (*) => Send("o"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "p").OnEvent("Click", (*) => Send("p"))

    quickGui.Add("Button", "w25 h30 x20 y+10", "a").OnEvent("Click", (*) => Send("a"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "s").OnEvent("Click", (*) => Send("s"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "d").OnEvent("Click", (*) => Send("d"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "f").OnEvent("Click", (*) => Send("f"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "g").OnEvent("Click", (*) => Send("g"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "h").OnEvent("Click", (*) => Send("h"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "j").OnEvent("Click", (*) => Send("j"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "k").OnEvent("Click", (*) => Send("k"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "l").OnEvent("Click", (*) => Send("l"))

    quickGui.Add("Button", "w25 h30 x33 y+10", "z").OnEvent("Click", (*) => Send("z"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "x").OnEvent("Click", (*) => Send("x"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "c").OnEvent("Click", (*) => Send("c"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "v").OnEvent("Click", (*) => Send("v"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "b").OnEvent("Click", (*) => Send("b"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "n").OnEvent("Click", (*) => Send("n"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "m").OnEvent("Click", (*) => Send("m"))
    quickGui.Add("Button", "w25 h30 x+5 yp", "空").OnEvent("Click", (*) => Send("{Space}"))
    quickGui.Add("Button", "w25 h30 x+5 yp", ",").OnEvent("Click", (*) => Send(","))
}

TogglequickGuiWidth2(*) {
    global quickGui, isQuickGuiExpanded, quickGuiWidth1, quickGuiWidth2, quickGuiExpandedWidth3, quickGuiExpandedWidth4
    if (!IsObject(quickGui)) { ; 若面板尚未创建则先打开
        OpenQuickPanel()
        Sleep 50
    }
    if (isQuickGuiExpanded) {
        ; 恢复为当前 quickGuiWidth1/quickGuiWidth2（可以是原始值或外面修改后的值）
        quickGui.Move(, , quickGuiWidth1+2, quickGuiWidth2+36)
        isQuickGuiExpanded := false
    } else {
        ; 切换到展开尺寸（使用预设展开值）
        quickGui.Move(, , quickGuiExpandedWidth3+5, quickGuiExpandedWidth4)
        isQuickGuiExpanded := true
    }
}


; RestoreFocus 函数保持不变，用于恢复主 GUI 焦点
RestoreFocus(*) {
    global lastFocusedControl, myGui
    if (lastFocusedControl != "") {
        ControlFocus lastFocusedControl, "ahk_id " . myGui.Hwnd
    }
}

