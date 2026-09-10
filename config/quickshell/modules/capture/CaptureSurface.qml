import "../panels" as Panels

Panels.Panel {
    property int preferredHeight: 600
    signal closeRequested

    title: "Capture"
    icon: "\uf030"
    implicitWidth: 600
    implicitHeight: Math.min(preferredHeight, bodyHeight + 94)
    onCloseRequested: opened = false
}
