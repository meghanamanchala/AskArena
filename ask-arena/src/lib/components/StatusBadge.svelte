<script lang="ts">
	type EventStatus = 'waiting' | 'live' | 'closed';

	let { status }: { status: EventStatus } = $props();

	const classes: Record<EventStatus, string> = {
		waiting: 'bg-amber-100 text-amber-800 ring-amber-600/20',
		live: 'bg-emerald-100 text-emerald-800 ring-emerald-600/20',
		closed: 'bg-slate-200 text-slate-700 ring-slate-600/20'
	};

	const labels: Record<EventStatus, string> = {
		waiting: 'Waiting',
		live: 'Live',
		closed: 'Closed'
	};
</script>

<span class={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ring-1 ring-inset ${classes[status]}`}>
	{labels[status]}
</span>
