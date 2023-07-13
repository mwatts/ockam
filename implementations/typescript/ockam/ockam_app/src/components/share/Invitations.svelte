<script>
import { invoke } from '@tauri-apps/api/tauri'
import InvitationTable from './InvitationTable.svelte'

let list_invites = invoke('list_invites')

</script>

{#await list_invites}
  Loading...
{:then invites}
  <div class="grid grid-cols-1 lg:grid-cols-2">
    <InvitationTable invites={invites.sent} />
    <InvitationTable invites={invites.received} direction="received"/>
  </div>
{:catch error}
  {@debug error}
  Error!
{/await}
