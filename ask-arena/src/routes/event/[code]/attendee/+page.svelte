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
  let attendeeVoterId = '';
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

  const voteQuestion = async (question: { id: string }) => {
    if (!event || event.status !== 'live') return;

    const trimmedName = attendeeName.trim();
    if (!trimmedName) {
      errorMessage = 'Please add your name before voting.';
      return;
    }

    votingQuestionId = question.id;
    errorMessage = '';

    try {
      let { data, error } = await supabase.rpc('cast_vote', {
        p_question_id: question.id,
        p_voter_name: trimmedName,
        p_voter_id: attendeeVoterId
      });

      if (error?.code === 'PGRST202') {
        const legacyVoterName = `${trimmedName}::${attendeeVoterId}`;
        const fallback = await supabase.rpc('cast_vote', {
          p_question_id: question.id,
          p_voter_name: legacyVoterName
        });

        data = fallback.data;
        error = fallback.error;
      }

      if (error) {
        throw error;
      }

      if (!data) {
        errorMessage = 'Vote was not recorded. You may have already voted for this question.';
        return;
      }
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to vote for this question.';
    } finally {
      votingQuestionId = '';
    }
  };

  onMount(() => {
    let active = true;

    const voterStorageKey = 'askarena-voter-id';
    const existingVoterId = localStorage.getItem(voterStorageKey);
    if (existingVoterId) {
      attendeeVoterId = existingVoterId;
    } else {
      attendeeVoterId = crypto.randomUUID();
      localStorage.setItem(voterStorageKey, attendeeVoterId);
    }

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

<main class="page-shell">
  <div class="page-wrap grid gap-6 lg:grid-cols-[300px_1fr]">
    <Sidebar
      title="Attendee View"
      subtitle="Submit and vote while the event is live."
      links={[
        { label: 'Join another event', href: '/join' },
        { label: 'Go to landing', href: '/' }
      ]}
    >
      {#if event}
        <p class="muted-text text-xs uppercase tracking-[0.2em]">Event</p>
        <p class="theme-text mt-1 text-base font-semibold">{event.title}</p>
        <div class="mt-3"><StatusBadge status={event.status} /></div>
      {/if}
    </Sidebar>

    <section>
      {#if isLoading}
        <div class="neon-panel p-6 text-sm muted-text">Loading event...</div>
      {:else if errorMessage && !event}
        <div class="neon-panel p-6 text-sm text-rose-200">{errorMessage}</div>
      {:else if event}
        <div class="neon-panel p-5">
          <div class="flex flex-wrap items-center justify-between gap-4">
            <div>
              <h1 class="theme-text text-2xl font-black">{event.title}</h1>
              <p class="mt-1 text-sm muted-text">Hosted by {event.host_name} · Code {event.code}</p>
            </div>
            <StatusBadge status={event.status} />
          </div>

          {#if event.status === 'waiting'}
            <div class="mt-5 rounded-lg border border-amber-400/25 bg-amber-500/10 px-4 py-3 text-sm text-amber-200">Waiting for host to start the event.</div>
          {:else if event.status === 'closed'}
            <div class="mt-5 rounded-lg border border-slate-400/25 bg-slate-500/10 px-4 py-3 text-sm text-slate-300">This event is closed.</div>
          {:else}
            <form
              class="mt-5 space-y-3"
              onsubmit={(formEvent) => {
                formEvent.preventDefault();
                void submitQuestion();
              }}
            >
              <div>
                <label class="field-label" for="attendee-name">Your name</label>
                <input
                  id="attendee-name"
                  type="text"
                  required
                  maxlength="60"
                  bind:value={attendeeName}
                  class="field-input"
                />
              </div>
              <div>
                <label class="field-label" for="question">Ask a question</label>
                <textarea
                  id="question"
                  required
                  rows="3"
                  maxlength="500"
                  bind:value={questionContent}
                  class="field-input"
                  placeholder="What would you like to ask?"
                ></textarea>
              </div>

              {#if errorMessage}
                <p class="alert-error">{errorMessage}</p>
              {/if}

              <button
                type="submit"
                disabled={isSubmittingQuestion}
                class="btn-primary"
              >
                {isSubmittingQuestion ? 'Submitting...' : 'Submit Question'}
              </button>
            </form>
          {/if}
        </div>

        <div class="mt-6 neon-panel p-5">
          <h2 class="theme-text text-lg font-black uppercase tracking-[0.12em]">Questions</h2>
          <p class="mt-1 text-sm muted-text">Live list sorted by votes.</p>

          <div class="mt-4 space-y-3">
            {#if questions.length === 0}
              <p class="alert-info">No questions yet.</p>
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