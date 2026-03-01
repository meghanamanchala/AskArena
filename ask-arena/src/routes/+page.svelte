<script>
	import { supabase } from '$lib/supabase'

	let title = ""

	async function createEvent() {
		const code = Math.random().toString(36).substring(2, 8)

		const { data, error } = await supabase
			.from('events')
			.insert([
				{
					title,
					code,
					created_by: "host"
				}
			])

		console.log("Inserted:", data)
		console.log("Error:", error)
	}
</script>

<div class="p-6">
	<h1 class="text-2xl font-bold mb-4">Create Event</h1>

	<input
		class="border p-2 mr-2"
		placeholder="Event title"
		bind:value={title}
	/>

	<button
		class="bg-blue-500 text-white px-4 py-2"
		on:click={createEvent}
	>
		Create
	</button>
</div>