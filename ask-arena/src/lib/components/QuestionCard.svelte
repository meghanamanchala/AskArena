<script lang="ts">
	interface QuestionModel {
		id: string;
		content: string;
		author_name: string;
		votes: number;
		created_at: string;
	}

	let {
		question,
		onVote,
		canVote = true,
		isVoting = false
	}: {
		question: QuestionModel;
		onVote?: ((question: QuestionModel) => void) | undefined;
		canVote?: boolean;
		isVoting?: boolean;
	} = $props();
</script>

<article class="theme-question rounded-xl p-4">
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="theme-text text-sm">{question.content}</p>
			<p class="mt-2 text-xs uppercase tracking-[0.12em] text-slate-400">By {question.author_name}</p>
		</div>

		<div class="flex items-center gap-2">
			<span class="rounded-lg border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-sm font-semibold text-emerald-200">{question.votes}</span>
			{#if onVote}
				<button
					type="button"
					class="btn-primary px-3 py-1"
					onclick={() => onVote?.(question)}
					disabled={!canVote || isVoting}
				>
					{isVoting ? 'Voting...' : 'Vote'}
				</button>
			{/if}
		</div>
	</div>
</article>
