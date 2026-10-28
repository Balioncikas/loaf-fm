import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import app.loaf

// LoafSlider -- Material 3 slider used by the appearance settings.
Slider {
    id: control

    Layout.preferredWidth: 120
    implicitWidth: 120
    implicitHeight: 36

    // Announced to screen readers; also the visible label of the row.
    property string label: ""

    Accessible.name: label

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 6
        radius: 3
        color: theme.surfaceContainerHighest

        Rectangle {
            width: control.position * parent.width
            x: control.mirrored ? parent.width - width : 0
            height: parent.height
            radius: parent.radius
            color: control.enabled ? theme.primary : theme.outline
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        implicitWidth: 18
        implicitHeight: 24
        radius: 6
        color: control.enabled ? theme.primary : theme.outline
        border.width: control.activeFocus ? 2 : 0
        border.color: theme.textMain
    }
}
