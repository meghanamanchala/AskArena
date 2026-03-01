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

<section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="text-xs font-semibold uppercase tracking-wider text-slate-500">Event</p>
			<h2 class="mt-1 text-xl font-bold text-slate-900">{event.title}</h2>
			<p class="mt-2 text-sm text-slate-600">Hosted by {event.host_name}</p>
		</div>
		<StatusBadge status={event.status} />
	</div>

	<div class="mt-4 rounded-xl bg-slate-50 px-4 py-3">
		<p class="text-xs font-medium text-slate-500">Share code</p>
		<p class="mt-1 font-mono text-2xl font-black tracking-widest text-slate-900">{event.code}</p>
	</div>

	<div class="mt-4">
		{@render children?.()}
	</div>
</section>
