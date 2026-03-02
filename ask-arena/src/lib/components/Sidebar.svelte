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


<aside class="neon-panel p-5">
	<h2 class="theme-text text-lg font-black uppercase tracking-[0.12em]">{title}</h2>
	{#if subtitle}
		<p class="mt-2 text-sm muted-text">{subtitle}</p>
	{/if}

	{#if links.length > 0}
		<nav class="mt-4 space-y-2">
			{#each links as link}
				<a
					href={link.href}
					class="panel-chip theme-text block rounded-xl px-3 py-2 text-sm font-medium transition hover:border-cyan-300/30"
				>
					{link.label}
				</a>
			{/each}
		</nav>
	{/if}

	<div class="mt-5 border-t border-slate-500/20 pt-4">
		{@render children?.()}
	</div>
</aside>
