import "../panels" as Panels

Panels.Panel {
    signal closeRequested

    icon: "\uf030"
    implicitWidth: 600
    title: "Capture"

    onCloseRequested: opened = false
}
