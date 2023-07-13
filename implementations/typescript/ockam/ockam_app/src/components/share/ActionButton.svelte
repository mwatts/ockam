<script>
export let enabled = true;
const btnClass = enabled ? "first:rounded-l-lg last:rounded-r-lg mx-0 my-1 p-0 bg-natural-medium hover:bg-natural-light border-2 border-natural-neutral hover:border-natural-white text-primary-deep hover:text-secondary-avocado" : "first:rounded-l-lg last:rounded-r-lg mx-0 my-1 p-0 bg-natural-medium hover:bg-natural-light border-2 border-natural-neutral hover:border-natural-white text-primary-deep hover:text-secondary-avocado";
</script>

<button class={btnClass}>
  <slot />
</button>
