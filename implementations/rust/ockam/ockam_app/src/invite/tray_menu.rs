use crate::ctx::TauriCtx;
use ockam_api::cli_state::StateDirTrait;
use ockam_command::{CommandGlobalOpts, GlobalArgs};
use tauri::{CustomMenuItem, Manager};
use tracing::info;

pub(crate) const HEADER_MENU_ID: &str = "invite_header";
pub(crate) const INVITES_MENU_ID: &str = "manage_invites";

pub(crate) struct InviteTrayMenuSection {
    pub(crate) header: CustomMenuItem,
    pub(crate) manage_invites: CustomMenuItem,
}

impl InviteTrayMenuSection {
    // TODO: Is there a way to check this with less significant allocations or disk I/O?
    fn has_default_project() -> bool {
        let opts = CommandGlobalOpts::new(GlobalArgs::default());
        opts.state.projects.default().is_ok()
    }

    pub(crate) fn new() -> Self {
        let mut manage_invites = CustomMenuItem::new(INVITES_MENU_ID, "Manage Invites");
        if Self::has_default_project() {
            manage_invites = manage_invites.disabled();
        }

        Self {
            header: CustomMenuItem::new(HEADER_MENU_ID, "Invite and Share").disabled(),
            manage_invites,
        }
    }
}

impl Default for InviteTrayMenuSection {
    fn default() -> Self {
        Self::new()
    }
}

pub(crate) fn on_manage(ctx: TauriCtx) -> tauri::Result<()> {
    // TODO: prompt for address and port
    // TODO: open secure channel to Orchestrator
    // TODO: submit creation request payload
    // TODO: on success, add to Tauri state
    info!("manage called");
    if let Some(window) = ctx.app_handle().get_window("ockam") {
        window.show()?;
    }
    Ok(())
}
