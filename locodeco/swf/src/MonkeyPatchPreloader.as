package
{
import mx.preloaders.DownloadProgressBar;

// monkeypatches:
import mx.managers.ToolTipManagerImpl; ToolTipManagerImpl;

/**
 * This class is the Flex preloader which runs before RSLs are loaded into
 * memory. This allows me to patch classes that the RSL loads by loading them
 * here first.
 */
public class MonkeyPatchPreloader extends DownloadProgressBar
{
	//
}
}