<script lang="ts">
	import type { Snippet } from 'svelte';
	import StatusBadge from '$lib/components/StatusBadge.svelte';

	type EventStatus = 'waiting' | 'live' | 'closed';

	interface EventCardModel {
		title: string;
		code: string;
		host_name: string;
		status: EventStatus;
	}

	let {
		event,
		children
	}: {
		event: EventCardModel;
		children?: Snippet;
	} = $props();
</script>

<section class="neon-panel p-5">
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="neon-kicker">Event</p>
			<h2 class="theme-text mt-2 text-2xl font-black">{event.title}</h2>
			<p class="mt-2 text-sm muted-text">Hosted by {event.host_name}</p>
		</div>
		<StatusBadge status={event.status} />
	</div>

	<div class="mt-4 rounded-xl border border-cyan-300/15 bg-cyan-400/8 px-4 py-3">
		<p class="text-xs font-medium uppercase tracking-[0.2em] text-cyan-200/70">Share code</p>
		<p class="display-accent mt-1 font-mono text-2xl font-black tracking-widest">{event.code}</p>
	</div>

	<div class="mt-4">
		{@render children?.()}
	</div>
</section>
