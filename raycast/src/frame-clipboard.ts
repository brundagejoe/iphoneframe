import { getPreferenceValues, showHUD, showToast, Toast } from "@raycast/api";
import { frameClipboard } from "./run-compositor";

export default async function Command() {
  const preferences = getPreferenceValues<{
    projectDirectory?: string;
    fit?: string;
  }>();
  const toast = await showToast({
    style: Toast.Style.Animated,
    title: "Framing clipboard image",
  });
  try {
    await frameClipboard(
      preferences.projectDirectory || "~/Documents/projects/iphoneframe",
      preferences.fit || "contain",
    );
    await toast.hide();
    await showHUD("Framed iPhone image copied. Ready to paste.");
  } catch (error) {
    toast.style = Toast.Style.Failure;
    toast.title = "Could not frame clipboard image";
    toast.message = error instanceof Error ? error.message : String(error);
  }
}
