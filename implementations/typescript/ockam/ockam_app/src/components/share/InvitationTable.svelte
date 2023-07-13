<script>
import ReceivedInvite from './ReceivedInvite.svelte'
import SentInvitation from './SentInvitation.svelte'

export let direction = "sent";
export let invites;

$: comp = direction == "sent" ? SentInvitation : ReceivedInvite
$: title = direction == "sent" ? "Sent Invitations" : "Received Invitations"
$: email_header = direction == "sent" ? "Recipient" : "From"

</script>

<div class="bg-natural-neutral p-2 m-2 rounded-xl text-natural-light divide-y divide-natural-dark">
  <h2 class="text-2xl text-center">{title}</h2>
  <table class="table-auto w-full divide-y divide-natural-neutral">
    <thead>
      <tr class="divide-x divide-gray-300">
        <th>{email_header}</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody class="divide-y divide-dashed divide-gray-400">
      {#each invites as invite}
        <svelte:component this={comp} {invite} />
      {/each}
    </tbody>
  </table>
</div>
