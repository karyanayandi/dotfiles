import { View, div } from "gpui-kit";
import { focused, hc, nextCommand, notify, run } from "herdr";

export default class VimNavigation extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const direction = await nextCommand();
        try {
          await this.navigate(direction);
        } catch (error) {
          notify({ title: "Vim navigation failed", body: String(error) });
        }
        cx.notify();
      }
    });
  }

  async navigate(direction) {
    const key = { left: "h", down: "j", up: "k", right: "l" }[direction];
    if (!key) return;
    const terminal = focused()?.terminal;
    if (!terminal) {
      run("pane.go", { direction });
      return;
    }
    const result = await hc(["get", terminal, "--json"]);
    if (focused()?.terminal !== terminal) return;
    if (result.code !== 0) throw new Error(result.stderr);
    const name = JSON.parse(result.stdout).foreground?.name ?? "";
    if (/^g?(view|l?n?vim?x?)(diff)?$/i.test(name)) {
      const sent = await hc(["keys", terminal, `ctrl+${key}`]);
      if (sent.code !== 0) throw new Error(sent.stderr);
    } else {
      run("pane.go", { direction });
    }
  }

  render() {
    return div();
  }
}
