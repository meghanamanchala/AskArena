<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import QuestionCard from '$lib/components/QuestionCard.svelte';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import StatusBadge from '$lib/components/StatusBadge.svelte';
  import { supabase } from '$lib/supabase';

  type EventStatus = 'waiting' | 'live' | 'closed';

  interface EventRow {
    id: string;
    code: string;
    title: string;
    host_name: string;
    status: EventStatus;
    created_at: string;
  }

  interface QuestionRow {
    id: string;
    event_id: string;
    content: string;
    author_name: string;
    votes: number;
    created_at: string;
  }

  let event: EventRow | null = null;
  let questions: QuestionRow[] = [];
  let attendeeName = '';
  let questionContent = '';
  let errorMessage = '';
  let isLoading = true;
  let isSubmittingQuestion = false;
  let votingQuestionId = '';

  let questionChannel: ReturnType<typeof supabase.channel> | null = null;
  let statusChannel: ReturnType<typeof supabase.channel> | null = null;

  let code = '';

  $: code = $page.params.code?.toUpperCase() ?? '';

  const loadEvent = async () => {
    const { data, error } = await supabase
      .from('events')
      .select('*')
      .eq('code', code)
      .maybeSingle();

    if (error) {
      throw error;
    }

    if (!data) {
      throw new Error('Event not found.');
    }

    event = data as EventRow;
  };

  const loadQuestions = async () => {
    if (!event) {
      questions = [];
      return;
    }

    const { data, error } = await supabase
      .from('questions')
      .select('*')
      .eq('event_id', event.id)
      .order('votes', { ascending: false })
      .order('created_at', { ascending: true });

    if (error) {
      throw error;
    }

    questions = (data ?? []) as QuestionRow[];
  };

  const setupRealtime = () => {
    if (!event) return;

    questionChannel = supabase
      .channel(`attendee-questions-${event.id}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'questions', filter: `event_id=eq.${event.id}` },
        () => {
          void loadQuestions();
        }
      )
      .subscribe();

    statusChannel = supabase
      .channel(`attendee-event-status-${event.code}`)
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'events', filter: `code=eq.${event.code}` },
        (payload) => {
          if (!event) return;

          const next = payload.new as { status?: EventStatus };
          if (next.status) {
            event = { ...event, status: next.status };
          }
        }
      )
      .subscribe();
  };

  const clearRealtime = () => {
    if (questionChannel) {
      void supabase.removeChannel(questionChannel);
      questionChannel = null;
    }

    if (statusChannel) {
      void supabase.removeChannel(statusChannel);
      statusChannel = null;
    }
  };

  const submitQuestion = async () => {
    if (!event || event.status !== 'live') return;

    const trimmedContent = questionContent.trim();
    const trimmedName = attendeeName.trim();

    if (!trimmedContent || !trimmedName) {
      errorMessage = 'Please enter your name and question.';
      return;
    }

    isSubmittingQuestion = true;
    errorMessage = '';

    try {
      const { error } = await supabase.from('questions').insert({
        event_id: event.id,
        content: trimmedContent,
        author_name: trimmedName
      });

      if (error) {
        throw error;
      }

      questionContent = '';
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to submit question.';
    } finally {
      isSubmittingQuestion = false;
    }
  };

  const voteQuestion = async (question: { id: string; votes: number }) => {
    if (!event || event.status !== 'live') return;

    const trimmedName = attendeeName.trim();
    if (!trimmedName) {
      errorMessage = 'Please add your name before voting.';
      return;
    }

    votingQuestionId = question.id;
    errorMessage = '';

    try {
      const { data: existingVote, error: existingVoteError } = await supabase
        .from('votes')
        .select('id')
        .eq('question_id', question.id)
        .eq('voter_name', trimmedName)
        .maybeSingle();

      if (existingVoteError) {
        throw existingVoteError;
      }

      if (existingVote) {
        errorMessage = 'You have already voted for this question.';
        return;
      }

      const { error: voteInsertError } = await supabase.from('votes').insert({
        question_id: question.id,
        voter_name: trimmedName
      });

      if (voteInsertError) {
        throw voteInsertError;
      }

      const { error: questionUpdateError } = await supabase
        .from('questions')
        .update({ votes: question.votes + 1 })
        .eq('id', question.id);

      if (questionUpdateError) {
        throw questionUpdateError;
      }
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to vote for this question.';
    } finally {
      votingQuestionId = '';
    }
  };

  onMount(() => {
    let active = true;

    const nameFromQuery = $page.url.searchParams.get('name');
    if (nameFromQuery) {
      attendeeName = nameFromQuery;
    }

    const init = async () => {
      isLoading = true;
      errorMessage = '';

      try {
        await loadEvent();
        await loadQuestions();

        if (active) {
          setupRealtime();
        }
      } catch (error) {
        errorMessage = error instanceof Error ? error.message : 'Unable to load event.';
      } finally {
        isLoading = false;
      }
    };

    void init();

    return () => {
      active = false;
      clearRealtime();
    };
  });
</script>

<main class="min-h-screen bg-slate-50 px-4 py-8">
  <div class="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[300px_1fr]">
    <Sidebar
      title="Attendee View"
      subtitle="Submit and vote while the event is live."
      links={[
        { label: 'Join another event', href: '/join' },
        { label: 'Go to landing', href: '/' }
      ]}
    >
      {#if event}
        <p class="text-sm text-slate-600">Event</p>
        <p class="mt-1 text-base font-semibold text-slate-900">{event.title}</p>
        <div class="mt-3"><StatusBadge status={event.status} /></div>
      {/if}
    </Sidebar>

    <section>
      {#if isLoading}
        <div class="rounded-2xl border border-slate-200 bg-white p-6 text-sm text-slate-600 shadow-sm">Loading event...</div>
      {:else if errorMessage && !event}
        <div class="rounded-2xl border border-rose-200 bg-rose-50 p-6 text-sm text-rose-700 shadow-sm">{errorMessage}</div>
      {:else if event}
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="flex flex-wrap items-center justify-between gap-4">
            <div>
              <h1 class="text-2xl font-bold text-slate-900">{event.title}</h1>
              <p class="mt-1 text-sm text-slate-600">Hosted by {event.host_name} · Code {event.code}</p>
            </div>
            <StatusBadge status={event.status} />
          </div>

          {#if event.status === 'waiting'}
            <div class="mt-5 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">Waiting for host to start the event.</div>
          {:else if event.status === 'closed'}
            <div class="mt-5 rounded-lg bg-slate-100 px-4 py-3 text-sm text-slate-700">This event is closed.</div>
          {:else}
            <form
              class="mt-5 space-y-3"
              onsubmit={(formEvent) => {
                formEvent.preventDefault();
                void submitQuestion();
              }}
            >
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700" for="attendee-name">Your name</label>
                <input
                  id="attendee-name"
                  type="text"
                  required
                  maxlength="60"
                  bind:value={attendeeName}
                  class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label class="mb-1 block text-sm font-medium text-slate-700" for="question">Ask a question</label>
                <textarea
                  id="question"
                  required
                  rows="3"
                  maxlength="500"
                  bind:value={questionContent}
                  class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
                  placeholder="What would you like to ask?"
                ></textarea>
              </div>

              {#if errorMessage}
                <p class="rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">{errorMessage}</p>
              {/if}

              <button
                type="submit"
                disabled={isSubmittingQuestion}
                class="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-slate-400"
              >
                {isSubmittingQuestion ? 'Submitting...' : 'Submit Question'}
              </button>
            </form>
          {/if}
        </div>

        <div class="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <h2 class="text-lg font-bold text-slate-900">Questions</h2>
          <p class="mt-1 text-sm text-slate-600">Live list sorted by votes.</p>

          <div class="mt-4 space-y-3">
            {#if questions.length === 0}
              <p class="rounded-lg bg-slate-50 px-4 py-3 text-sm text-slate-600">No questions yet.</p>
            {:else}
              {#each questions as question (question.id)}
                <QuestionCard
                  {question}
                  onVote={voteQuestion}
                  canVote={event.status === 'live'}
                  isVoting={votingQuestionId === question.id}
                />
              {/each}
            {/if}
          </div>
        </div>
      {/if}
    </section>
  </div>
</main>