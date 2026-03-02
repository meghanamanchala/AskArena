<script lang="ts">
	import { onMount } from 'svelte';
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();

	type Theme = 'light' | 'dark';
	type ThemeMode = 'system' | Theme;

	let theme = $state<Theme>('dark');
	let mode = $state<ThemeMode>('system');
	let isMenuOpen = $state(false);
	let switcherElement: HTMLDivElement | null = null;

	const storageKey = 'askarena-theme';
	const modeLabels: Record<ThemeMode, string> = {
		system: 'System',
		dark: 'Dark',
		light: 'Light'
	};

	const resolveSystemTheme = (): Theme =>
		window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';

	const applyTheme = (nextTheme: Theme) => {
		document.documentElement.dataset.theme = nextTheme;
		theme = nextTheme;
	};

	const applyMode = (nextMode: ThemeMode, persist = true) => {
		mode = nextMode;
		const nextTheme = nextMode === 'system' ? resolveSystemTheme() : nextMode;
		applyTheme(nextTheme);

		if (persist) {
			localStorage.setItem(storageKey, nextMode);
		}
	};

	const setMode = (nextMode: ThemeMode) => {
		applyMode(nextMode);
		isMenuOpen = false;
	};

	onMount(() => {
		const savedMode = localStorage.getItem(storageKey);
		if (savedMode === 'light' || savedMode === 'dark' || savedMode === 'system') {
			applyMode(savedMode as ThemeMode, false);
		} else {
			applyMode('system', false);
		}

		const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
		const onSystemThemeChange = () => {
			if (mode === 'system') {
				applyMode('system', false);
			}
		};

		const onDocumentPointerDown = (event: PointerEvent) => {
			if (!isMenuOpen || !switcherElement) return;

			const target = event.target;
			if (target instanceof Node && !switcherElement.contains(target)) {
				isMenuOpen = false;
			}
		};

		const onDocumentKeyDown = (event: KeyboardEvent) => {
			if (event.key === 'Escape') {
				isMenuOpen = false;
			}
		};

		mediaQuery.addEventListener('change', onSystemThemeChange);
		window.addEventListener('pointerdown', onDocumentPointerDown);
		window.addEventListener('keydown', onDocumentKeyDown);

		return () => {
			mediaQuery.removeEventListener('change', onSystemThemeChange);
			window.removeEventListener('pointerdown', onDocumentPointerDown);
			window.removeEventListener('keydown', onDocumentKeyDown);
		};
	});
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<script>
		(() => {
			try {
				const key = 'askarena-theme';
				const saved = localStorage.getItem(key);
				const system = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
				const mode = saved === 'light' || saved === 'dark' || saved === 'system' ? saved : 'system';
				document.documentElement.dataset.theme = mode === 'system' ? system : mode;
			} catch {
				document.documentElement.dataset.theme = 'dark';
			}
		})();
	</script>
</svelte:head>

<div class="theme-switcher" bind:this={switcherElement}>
	<button
		type="button"
		class="theme-toggle"
		onclick={() => (isMenuOpen = !isMenuOpen)}
		aria-label="Theme mode"
		aria-haspopup="menu"
		aria-expanded={isMenuOpen}
		title="Theme mode"
	>
		<span aria-hidden="true">{theme === 'dark' ? '🌙' : '☀️'}</span>
		<span>{modeLabels[mode]}</span>
		<span aria-hidden="true">▾</span>
	</button>

	{#if isMenuOpen}
		<div class="theme-menu" role="menu" aria-label="Theme options">
			<button type="button" role="menuitemradio" aria-checked={mode === 'system'} class:active={mode === 'system'} onclick={() => setMode('system')}>
				System
			</button>
			<button type="button" role="menuitemradio" aria-checked={mode === 'dark'} class:active={mode === 'dark'} onclick={() => setMode('dark')}>
				Dark
			</button>
			<button type="button" role="menuitemradio" aria-checked={mode === 'light'} class:active={mode === 'light'} onclick={() => setMode('light')}>
				Light
			</button>
		</div>
	{/if}
</div>

{@render children()}
