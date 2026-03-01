<script lang="ts">
	import type { Snippet } from 'svelte';

	interface SidebarLink {
		label: string;
		href: string;
	}

	let {
		title,
		subtitle,
		links = [],
		children
	}: {
		title: string;
		subtitle?: string;
		links?: SidebarLink[];
		children?: Snippet;
	} = $props();
</script>

<aside class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
	<h2 class="text-lg font-bold text-slate-900">{title}</h2>
	{#if subtitle}
		<p class="mt-1 text-sm text-slate-600">{subtitle}</p>
	{/if}

	{#if links.length > 0}
		<nav class="mt-4 space-y-2">
			{#each links as link}
				<a
					href={link.href}
					class="block rounded-lg px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 hover:text-slate-900"
				>
					{link.label}
				</a>
			{/each}
		</nav>
	{/if}

	<div class="mt-5 border-t border-slate-200 pt-4">
		{@render children?.()}
	</div>
</aside>
