use tauri::async_runtime::RwLock;

use super::{InviteState, ReceivedInvite, SentInvite};

type State = InviteState<ReceivedInvite, SentInvite>;

// At time of writing, tauri::command requires pub not pub(crate)
#[tauri::command]
pub async fn list_invites(
    state: tauri::State<'_, RwLock<State>>,
) -> Result<InviteState<ReceivedInvite, SentInvite>, ()> {
    let reader = state.read().await;
    Ok(reader.clone())
}
