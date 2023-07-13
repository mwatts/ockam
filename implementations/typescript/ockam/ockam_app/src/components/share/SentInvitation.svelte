<script>
import ActionButton from './ActionButton.svelte'

export let invite;
</script>

<tr class="divide-x divide-dashed divide-gray-300">
  <th scope="row">{invite.recipient_email}</th>
  <td class="text-center">{invite.status}</td>
  <td class="w-64 p-0 m-0 text-center">
    {#if invite.status == "Online"}
      <ActionButton>Services</ActionButton>
      <ActionButton>Disconnect</ActionButton>
    {:else if invite.status == "Pending"}
      <ActionButton>Cancel</ActionButton>
    {/if}
  </td>
</tr>

<!--
<tr class="divide-x divide-dashed divide-gray-300">
  <th scope="row">another1@example.com</th>
  <td>2023-07-13 17:00</td>
  <td class="text-center">Invite Pending</td>
  <td class="w-64 p-0 m-0 text-center">
    <button class="rounded-l-lg mx-0 my-1 p-0.5 bg-slate-300 text-black">Redeliver</button>
    <button class="rounded-r-lg mx-0 my-1 p-0.5 bg-slate-300 text-black">Cancel</button>
  </td>
</tr>
-->
