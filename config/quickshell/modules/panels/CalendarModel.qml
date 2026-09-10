import QtQuick

QtObject {
    property date selected: new Date()
    readonly property date month: new Date(selected.getFullYear(), selected.getMonth(), 1, 12)

    function dayAt(index) {
        // Monday-first grid. Noon avoids midnight DST boundaries.
        return new Date(month.getFullYear(), month.getMonth(), 1 - (month.getDay() + 6) % 7 + index, 12);
    }

    function moveDays(days) {
        selected = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate() + days, 12);
    }

    function moveMonth(delta) {
        const last = new Date(selected.getFullYear(), selected.getMonth() + delta + 1, 0, 12).getDate();
        selected = new Date(selected.getFullYear(), selected.getMonth() + delta, Math.min(selected.getDate(), last), 12);
    }
}
