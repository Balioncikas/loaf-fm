import QtQuick
import QtQuick.Controls
import QtTest
import app.loaf

// Use the application's registered model and embedded FilePane. TestCase's
// mouse helpers dispatch through Qt's hit testing, rather than calling handlers.
ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    property var cutSet: ({})
    property bool keyboardNavActive: false
    property var activePane: pane
    property int menus: 0
    property int opened: 0
    property int tabs: 0
    function systemIcon(name) { return ""; }
    function defocusInputs() {}
    function openItemMenu() { menus++; }
    function openEmptyMenu() { menus++; }
    function openItem() { opened++; }
    function newTab() { tabs++; }

    LoafCore { id: core }
    Theme { id: theme; reduceMotionSetting: true }
    QtObject { id: contextMenu; function close() {} }
    QtObject {
        id: dragManager
        property string hoverTarget: ""
        property point cursorPos: Qt.point(0, 0)
        property bool isRmb: false
        property int starts: 0
        property int ends: 0
        property var paths: []
        function hover() {}
        function begin(selected, mouse) { starts++; paths = selected; }
        function end() { ends++; }
    }
    FilePane { id: pane; anchors.fill: parent; showHeader: false }
    TestCase { id: events; when: false }

    function check(condition, message) {
        if (!condition)
            throw new Error(message);
    }
    function findVisual(item, predicate) {
        if (predicate(item))
            return item;
        var children = item.children || [];
        for (var i = 0; i < children.length; ++i) {
            var found = findVisual(children[i], predicate);
            if (found)
                return found;
        }
        return null;
    }
    function selectionMouse(view) {
        return findVisual(view.contentItem, function(item) { return typeof item.updateBand === "function"; });
    }
    function reset(view) {
        events.wait(80); // Let click suppression from the previous drag expire.
        view.contentY = view.originY;
        pane.clearSelection();
        events.wait(20);
    }
    function drag(view, x1, y1, x2, y2, modifiers) {
        modifiers = modifiers || Qt.NoModifier;
        var starts = dragManager.starts;
        events.mousePress(view, x1, y1, Qt.LeftButton, modifiers);
        events.mouseMove(view, x2, y2, 10, Qt.LeftButton, modifiers);
        var bg = selectionMouse(view);
        check(bg && bg.active, "drag did not reach selection background: " + x1 + "," + y1 + " -> " + x2 + "," + y2 + "; active=" + (bg ? bg.active : "missing") + "; selected=" + pane.selectedCount + "; fileDrags=" + (dragManager.starts-starts));
        check(dragManager.starts === starts, "selection started a file drag");
        events.mouseRelease(view, x2, y2, Qt.LeftButton, modifiers);
        events.wait(80);
        check(!bg.active, "release left the selection box active");
    }
    function folder(name, count) {
        pane.engine.set_path(core.get_setting("selectionTestRoot") + "/" + name);
        for (var i = 0; i < 100 && (pane.engine.loading || pane.engine.item_count !== count); ++i)
            events.wait(10);
        check(pane.engine.item_count === count, "fixture did not load");
        events.wait(50);
    }
    function run() {
        try {
            theme.reduceMotionSetting = true;
            pane.engine.set_view("grid");
            folder("small", 8);
            var grid = findVisual(pane, function(item) { return item.cellWidth !== undefined; });
            var list = findVisual(pane, function(item) { return item.cacheBuffer !== undefined && item.spacing !== undefined && item.cellWidth === undefined; });
            check(grid && list, "views not found");
            var cw = grid.cellWidth, ch = grid.cellHeight;
            reset(grid);
            drag(grid, cw - 2, 20, 2 * cw - 10, 2 * ch - 10);
            check(pane.selectedCount === 2, "grid vertical gap: wrong selection");
            reset(grid);
            drag(grid, 2 * cw - 2, 2 * ch - 2, cw + 5, 20);
            check(pane.selectedCount === 2, "grid reverse drag: wrong selection");
            reset(grid);
            drag(grid, 20, ch - 2, 2 * cw - 10, 2 * ch - 10);
            check(pane.selectedCount === 2, "grid horizontal gap: wrong selection");
            console.log("SELECTION_CASE grid gaps and reverse direction");

            // Item dragging must still reach the drag manager with the file path.
            reset(grid);
            var starts = dragManager.starts, ends = dragManager.ends;
            events.mouseDrag(grid, 40, 40, 35, 35, Qt.LeftButton);
            check(dragManager.starts === starts + 1 && dragManager.ends === ends + 1
                  && dragManager.paths.length === 1, "grid file drag changed");

            pane.engine.set_view("list");
            events.wait(80);
            var rowHeight = Math.round(38 * Math.max(0.85, Math.min(1.3, pane.zoom)));
            var pitch = rowHeight + list.spacing;
            reset(list);
            drag(list, list.width - 25, 15, 400, 3 * pitch + 20);
            check(pane.selectedCount === 4, "list whitespace: wrong selection");
            reset(list);
            drag(list, list.width - 25, 15, list.width - 25, 3 * pitch + 20);
            check(pane.selectedCount === 4, "vertical list drag: wrong selection");
            reset(list);
            drag(list, 400, 3 * pitch + 20, list.width - 25, 15);
            check(pane.selectedCount === 4, "list reverse drag: wrong selection");
            reset(list);
            drag(list, 200, rowHeight + 1, 400, 3 * pitch + 20);
            check(pane.selectedCount === 3, "list row gap: wrong selection");
            reset(list);
            drag(list, list.width - 25, 8 * pitch + 15, 400, 15);
            check(pane.selectedCount === 8, "list footer blocked selection");
            console.log("SELECTION_CASE list whitespace, row gaps, footer and reverse direction");

            for (var modifier of [Qt.ControlModifier, Qt.ShiftModifier]) {
                reset(list);
                pane.selectRow(7, false, false);
                drag(list, list.width - 25, 15, 400, 2 * pitch + 20, modifier);
                check(pane.selectedCount === 4 && pane.selection[pane.engine.path_at(7)],
                      "modifier did not retain the existing selection");
            }
            reset(list);
            starts = dragManager.starts; ends = dragManager.ends;
            events.mouseDrag(list, 25, 15, 35, 20, Qt.LeftButton);
            check(dragManager.starts === starts + 1 && dragManager.ends === ends + 1
                  && dragManager.paths[0] === pane.engine.path_at(0), "list file drag changed");
            reset(list);
            events.mouseClick(list, list.width - 25, 15, Qt.LeftButton);
            check(pane.selectedCount === 1, "whitespace click no longer selects the row");
            var previous = menus;
            events.mouseClick(list, 25, 15, Qt.RightButton);
            check(menus === previous + 1, "item context menu changed");
            previous = opened;
            events.mouseDoubleClickSequence(list, list.width - 25, 15, Qt.LeftButton);
            check(opened === previous + 1, "row double click changed");
            console.log("SELECTION_CASE modifiers, clicks, menus and file dragging");

            // A scrolled list uses content coordinates, including edge scrolling.
            folder("large", 80);
            reset(list);
            list.contentY = 10 * pitch;
            events.wait(20);
            drag(list, list.width - 25, 15, 400, 2 * pitch + 20);
            check(pane.selectedCount === 3 && pane.selection[pane.engine.path_at(10)],
                  "scrolled list selected the wrong rows");
            reset(list);
            events.mousePress(list, list.width - 25, 15, Qt.LeftButton);
            events.mouseMove(list, 400, list.height - 5, 10, Qt.LeftButton);
            var before = list.contentY;
            var countBefore = pane.selectedCount;
            events.wait(160);
            check(list.contentY > before, "selection did not scroll at the edge");
            check(pane.selectedCount > countBefore, "edge scrolling did not extend selection");
            events.mouseRelease(list, 400, list.height - 5, Qt.LeftButton);
            check(!selectionMouse(list).active, "scrolling drag did not release");

            pane.engine.set_view("grid");
            reset(grid);
            events.mousePress(grid, cw - 2, 20, Qt.LeftButton);
            events.mouseMove(grid, 2 * cw - 10, grid.height - 5, 10, Qt.LeftButton);
            before = grid.contentY;
            countBefore = pane.selectedCount;
            events.wait(240);
            check(grid.contentY > before && pane.selectedCount > countBefore,
                  "grid edge scrolling did not extend selection");
            events.mouseRelease(grid, 2 * cw - 10, grid.height - 5, Qt.LeftButton);
            pane.engine.set_view("list");

            theme.zoomIndex = 3;
            reset(list);
            pitch = Math.round(38 * Math.max(0.85, Math.min(1.3, pane.zoom))) + list.spacing;
            drag(list, list.width - 25, 15, 400, 2 * pitch + 20);
            check(pane.selectedCount === 3, "zoomed list selected the wrong rows");

            reset(list);
            theme.dragAction = "scroll";
            events.mousePress(list, 1, 15, Qt.LeftButton);
            events.mouseMove(list, 1, 100, 10, Qt.LeftButton);
            check(!selectionMouse(list).active, "pan mode started a selection box");
            events.mouseRelease(list, 1, 100, Qt.LeftButton);
            console.log("SELECTION_CASE scrolling, release, zoom and pan setting");
            console.log("FILE_SELECTION_PASS");
        } catch (error) {
            console.error("FILE_SELECTION_FAIL: " + error.message);
        }
        Qt.quit();
    }
    Timer { interval: 50; running: true; onTriggered: window.run() }
}
