<script lang="ts">
	type EventStatus = 'waiting' | 'live' | 'closed';

	let { status }: { status: EventStatus } = $props();

	const classes: Record<EventStatus, string> = {
		waiting: 'border border-amber-500/25 bg-amber-500/10 text-amber-200',
		live: 'border border-emerald-400/30 bg-emerald-400/15 text-emerald-200',
		closed: 'border border-slate-400/25 bg-slate-500/10 text-slate-300'
	};

	const labels: Record<EventStatus, string> = {
		waiting: 'Waiting',
		live: 'Live',
		closed: 'Closed'
	};
</script>

<span class={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-[0.16em] ${classes[status]}`}>
	{labels[status]}
</span>
