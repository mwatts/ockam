<script>
import ActionButton from './ActionButton.svelte'

export let invite;
</script>

<tr class="divide-x divide-dashed divide-gray-300">
  <th scope="row">{invite.from}</th>
  <td class="text-center">{invite.status}</td>
  <td class="w-64 p-0 m-0 text-center">
    {#if invite.status == "Pending"}
      <ActionButton>Accept</ActionButton>
      <ActionButton>Decline</ActionButton>
    {:else if invite.status == "Available"}
      <ActionButton>Connect</ActionButton>
    {:else if invite.status == "Connected"}
      <ActionButton>Disconnect</ActionButton>
    {:else if invite.status == "Offline"}
      <ActionButton enabled=false>Connect</ActionButton>
    {:else if invite.status == "Expired"}
      <ActionButton>Remove</ActionButton>
    {/if}
  </td>
</tr>

