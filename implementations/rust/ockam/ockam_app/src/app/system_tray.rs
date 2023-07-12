use crate::ctx::TauriCtx;
use crate::enroll::EnrollActions;
use crate::invite::InviteTrayMenuSection;
use crate::quit::QuitActions;
use crate::tcp::outlet::TcpOutletActions;
use crate::Result;
use tauri::{CustomMenuItem, SystemTrayMenu, SystemTrayMenuItem};

/// Create the system tray with all the major functions.
/// Separate groups of related functions with a native separator.
pub struct SystemTrayMenuBuilder {
    enroll: EnrollActions,
    invite: InviteTrayMenuSection,
    tcp: TcpOutletActions,
    quit: QuitActions,
}

impl SystemTrayMenuBuilder {
    /// Create the default system tray menu with the basic elements (i.e. without list items).
    pub fn default() -> SystemTrayMenu {
        Self::init().build()
    }

    pub fn init() -> Self {
        let enroll = EnrollActions::new();
        let invite = InviteTrayMenuSection::new();
        let tcp = TcpOutletActions::new();
        let quit = QuitActions::new();
        Self {
            enroll,
            invite,
            tcp,
            quit,
        }
    }

    /// Create a `SystemTrayMenu` instance, adding the menu items in the expected order.
    pub fn build(self) -> SystemTrayMenu {
        let menu = SystemTrayMenu::new()
            .add_menu_items(&[self.enroll.enroll])
            .add_native_item(SystemTrayMenuItem::Separator)
            .add_menu_items(&self.tcp.menu_items);
        #[cfg(feature = "invite")]
        let menu = menu
            .add_native_item(SystemTrayMenuItem::Separator)
            .add_menu_items(&[self.invite.header, self.invite.manage_invites]);
        menu.add_native_item(SystemTrayMenuItem::Separator)
            .add_menu_items(&[self.enroll.reset, self.quit.quit])
    }

    /// Refresh the system tray menu with the latest state, including all list items.
    pub fn refresh(ctx: &TauriCtx) -> Result<()> {
        let menu = Self::get_full_menu(ctx).unwrap_or(Self::default());
        ctx.app_handle().tray_handle().set_menu(menu)?;
        Ok(())
    }

    fn get_full_menu(ctx: &TauriCtx) -> Result<SystemTrayMenu> {
        let enroll = EnrollActions::new();
        let invite = InviteTrayMenuSection::new();
        let tcp = TcpOutletActions::full(ctx)?;
        let quit = QuitActions::new();
        let menu = Self {
            enroll,
            invite,
            tcp,
            quit,
        }
        .build();
        Ok(menu)
    }
}

/// This trait provides a way to add a list of
/// custom menu items to the SystemTray so that we
/// can define the behaviour of those items in separate modules.
pub(crate) trait SystemTrayMenuItems {
    fn add_menu_items(self, items: &[CustomMenuItem]) -> Self;
}

impl SystemTrayMenuItems for SystemTrayMenu {
    fn add_menu_items(self, items: &[CustomMenuItem]) -> Self {
        let mut tm = self;
        for item in items.iter() {
            tm = tm.add_item(item.clone());
        }
        tm
    }
}
