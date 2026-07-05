<script lang="ts">
	interface QuestionModel {
		id: string;
		content: string;
		author_name: string;
		votes: number;
		created_at: string;
		is_answered?: boolean;
		is_deleted?: boolean;
	}

	let {
		question,
		onVote,
		onMarkAnswered,
		onDelete,
		canVote = true,
		isVoting = false,
		hasVoted = false
	}: {
		question: QuestionModel;
		onVote?: ((question: QuestionModel) => void) | undefined;
		onMarkAnswered?: ((question: QuestionModel) => void) | undefined;
		onDelete?: ((question: QuestionModel) => void) | undefined;
		canVote?: boolean;
		isVoting?: boolean;
		hasVoted?: boolean;
	} = $props();
</script>

<article class={`theme-question rounded-xl p-4 transition-opacity ${question.is_answered ? 'opacity-60' : ''}`}>
	<div class="flex items-start justify-between gap-4">
		<div>
			<p class="theme-text text-sm">{question.content}</p>
			<div class="mt-2 flex flex-wrap items-center gap-3">
				<p class="text-xs uppercase tracking-[0.12em] text-slate-400">By {question.author_name}</p>
				{#if question.is_answered}
					<span class="inline-flex items-center rounded-full bg-cyan-400/10 px-2.5 py-0.5 text-xs font-semibold text-cyan-300">Answered</span>
				{/if}
				{#if onMarkAnswered && !question.is_answered}
					<button
						type="button"
						class="text-xs font-bold uppercase tracking-[0.12em] text-cyan-400 hover:text-cyan-300 transition cursor-pointer"
						onclick={() => onMarkAnswered?.(question)}
					>
						✓ Answered
					</button>
				{/if}
				{#if onDelete}
					<button
						type="button"
						class="text-xs font-bold uppercase tracking-[0.12em] text-rose-400 hover:text-rose-300 transition cursor-pointer"
						onclick={() => onDelete?.(question)}
					>
						🗑️ Delete
					</button>
				{/if}
			</div>
		</div>

		<div class="flex items-center gap-2">
			<span class="rounded-lg border border-emerald-400/20 bg-emerald-400/10 px-3 py-1 text-sm font-semibold text-emerald-200">{question.votes}</span>
			{#if onVote && !question.is_answered}
				<button
					type="button"
					class={hasVoted ? "border border-emerald-500/30 bg-emerald-500/10 px-3 py-1 text-sm font-semibold text-emerald-300 cursor-default rounded-xl" : "btn-primary px-3 py-1"}
					onclick={() => !hasVoted && onVote?.(question)}
					disabled={(!hasVoted && !canVote) || isVoting}
				>
					{#if isVoting}
						Voting...
					{:else if hasVoted}
						✓ Voted
					{:else}
						Vote
					{/if}
				</button>
			{/if}
		</div>
	</div>
</article>

