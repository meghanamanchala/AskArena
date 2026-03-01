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

<article class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="text-sm text-slate-800">{question.content}</p>
			<p class="mt-2 text-xs text-slate-500">By {question.author_name}</p>
		</div>

		<div class="flex items-center gap-2">
			<span class="rounded-lg bg-slate-100 px-3 py-1 text-sm font-semibold text-slate-800">{question.votes}</span>
			{#if onVote}
				<button
					type="button"
					class="rounded-lg bg-indigo-600 px-3 py-1 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-slate-400"
					onclick={() => onVote?.(question)}
					disabled={!canVote || isVoting}
				>
					{isVoting ? 'Voting...' : 'Vote'}
				</button>
			{/if}
		</div>
	</div>
</article>
