import Foundation
import Carbon.HIToolbox

/// キーコードからキー名への変換マッパー
struct KeyCodeMapper {
    
    /// キーコードからキー名を取得
    static func keyName(for keyCode: Int) -> String {
        return keyCodeMap[keyCode] ?? "Key\(keyCode)"
    }
    
    /// 主要なキーコードマップ
    private static let keyCodeMap: [Int: String] = [
        // アルファベット
        kVK_ANSI_A: "A",
        kVK_ANSI_S: "S",
        kVK_ANSI_D: "D",
        kVK_ANSI_F: "F",
        kVK_ANSI_H: "H",
        kVK_ANSI_G: "G",
        kVK_ANSI_Z: "Z",
        kVK_ANSI_X: "X",
        kVK_ANSI_C: "C",
        kVK_ANSI_V: "V",
        kVK_ANSI_B: "B",
        kVK_ANSI_Q: "Q",
        kVK_ANSI_W: "W",
        kVK_ANSI_E: "E",
        kVK_ANSI_R: "R",
        kVK_ANSI_Y: "Y",
        kVK_ANSI_T: "T",
        kVK_ANSI_1: "1",
        kVK_ANSI_2: "2",
        kVK_ANSI_3: "3",
        kVK_ANSI_4: "4",
        kVK_ANSI_6: "6",
        kVK_ANSI_5: "5",
        kVK_ANSI_Equal: "=",
        kVK_ANSI_9: "9",
        kVK_ANSI_7: "7",
        kVK_ANSI_Minus: "-",
        kVK_ANSI_8: "8",
        kVK_ANSI_0: "0",
        kVK_ANSI_RightBracket: "]",
        kVK_ANSI_O: "O",
        kVK_ANSI_U: "U",
        kVK_ANSI_LeftBracket: "[",
        kVK_ANSI_I: "I",
        kVK_ANSI_P: "P",
        kVK_ANSI_L: "L",
        kVK_ANSI_J: "J",
        kVK_ANSI_Quote: "'",
        kVK_ANSI_K: "K",
        kVK_ANSI_Semicolon: ";",
        kVK_ANSI_Backslash: "\\",
        kVK_ANSI_Comma: ",",
        kVK_ANSI_Slash: "/",
        kVK_ANSI_N: "N",
        kVK_ANSI_M: "M",
        kVK_ANSI_Period: ".",
        kVK_ANSI_Grave: "`",
        
        // 特殊キー
        kVK_Return: "Return",
        kVK_Tab: "Tab",
        kVK_Space: "Space",
        kVK_Delete: "Delete",
        kVK_Escape: "Escape",
        kVK_Command: "Command",
        kVK_Shift: "Shift",
        kVK_CapsLock: "CapsLock",
        kVK_Option: "Option",
        kVK_Control: "Control",
        kVK_RightCommand: "RightCommand",
        kVK_RightShift: "RightShift",
        kVK_RightOption: "RightOption",
        kVK_RightControl: "RightControl",
        kVK_Function: "Function",
        
        // ファンクションキー
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_F20: "F20",
        
        // 矢印キー
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_DownArrow: "↓",
        kVK_UpArrow: "↑",
        
        // その他
        kVK_Home: "Home",
        kVK_End: "End",
        kVK_PageUp: "PageUp",
        kVK_PageDown: "PageDown",
        kVK_ForwardDelete: "ForwardDelete",
        kVK_Help: "Help",
        kVK_Mute: "Mute",
        kVK_VolumeDown: "VolumeDown",
        kVK_VolumeUp: "VolumeUp",
        
        // テンキー
        kVK_ANSI_Keypad0: "Num0",
        kVK_ANSI_Keypad1: "Num1",
        kVK_ANSI_Keypad2: "Num2",
        kVK_ANSI_Keypad3: "Num3",
        kVK_ANSI_Keypad4: "Num4",
        kVK_ANSI_Keypad5: "Num5",
        kVK_ANSI_Keypad6: "Num6",
        kVK_ANSI_Keypad7: "Num7",
        kVK_ANSI_Keypad8: "Num8",
        kVK_ANSI_Keypad9: "Num9",
        kVK_ANSI_KeypadDecimal: "NumDecimal",
        kVK_ANSI_KeypadMultiply: "Num*",
        kVK_ANSI_KeypadPlus: "Num+",
        kVK_ANSI_KeypadClear: "NumClear",
        kVK_ANSI_KeypadDivide: "Num/",
        kVK_ANSI_KeypadEnter: "NumEnter",
        kVK_ANSI_KeypadMinus: "Num-",
        kVK_ANSI_KeypadEquals: "Num=",
    ]
    
    /// 修飾キーのみのキーコードかどうか
    static func isModifierKey(_ keyCode: Int) -> Bool {
        return [
            kVK_Command, kVK_Shift, kVK_CapsLock, kVK_Option, kVK_Control,
            kVK_RightCommand, kVK_RightShift, kVK_RightOption, kVK_RightControl,
            kVK_Function
        ].contains(keyCode)
    }
}
