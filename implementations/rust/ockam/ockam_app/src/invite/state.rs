use serde::Serialize;
use std::string::String;

#[derive(Clone, Debug, Serialize)]
enum SentStatus {
    Pending,
    #[allow(dead_code)]
    Accepted,
    Online,
    #[allow(dead_code)]
    Canceled,
}

#[derive(Clone, Debug, Serialize)]
enum ReceivedStatus {
    Pending,
    Available,
    #[allow(dead_code)]
    Connected,
    #[allow(dead_code)]
    Offline,
    Expired,
}

#[derive(Clone, Debug, Serialize)]
pub struct SentInvite {
    recipient_email: String,
    status: SentStatus,
}
#[derive(Clone, Debug, Serialize)]
pub struct ReceivedInvite {
    from: String,
    status: ReceivedStatus,
}

#[derive(Clone, Debug, Serialize)]
pub struct InviteState<R, S> {
    pub(crate) sent: Vec<S>,
    pub(crate) received: Vec<R>,
}

// Temporary stubbed data
impl Default for InviteState<ReceivedInvite, SentInvite> {
    fn default() -> Self {
        let sent = [
            ("user@example.com", SentStatus::Online),
            ("another1@example.com", SentStatus::Pending),
        ];

        let received = [
            ("boss@example.com", ReceivedStatus::Available),
            ("coworker@team.com", ReceivedStatus::Pending),
            ("friend@funny.tld", ReceivedStatus::Expired),
        ];
        Self {
            sent: sent
                .into_iter()
                .map(|(email, status)| SentInvite {
                    recipient_email: email.to_string(),
                    status,
                })
                .collect::<Vec<_>>(),
            received: received
                .into_iter()
                .map(|(email, status)| ReceivedInvite {
                    from: email.to_string(),
                    status,
                })
                .collect::<Vec<_>>(),
        }
    }
}
