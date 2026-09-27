import QtQuick
import QtTest

TestCase {
    function test_dates() {
        calendar.selected = new Date(2024, 0, 31, 12);
        calendar.moveMonth(1);
        compare(calendar.selected.getDate(), 29);
        compare(calendar.selected.getMonth(), 1);
        compare(calendar.dayAt(0).getDay(), 1);
        calendar.selected = new Date(2023, 11, 31, 12);
        calendar.moveDays(1);
        compare(calendar.selected.getFullYear(), 2024);
        compare(calendar.selected.getMonth(), 0);
        compare(calendar.selected.getDate(), 1);
        calendar.moveMonth(-1);
        compare(calendar.selected.getFullYear(), 2023);
        compare(calendar.selected.getMonth(), 11);
        compare(calendar.dayAt(41).getDay(), 0);
        calendar.selected = new Date(2023, 0, 31, 12);
        calendar.moveMonth(1);
        compare(calendar.selected.getDate(), 28);
    }

    name: "Calendar"

    CalendarModel {
        id: calendar
    }
}
