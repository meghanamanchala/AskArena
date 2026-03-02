<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import EventCard from '$lib/components/EventCard.svelte';
  import QuestionCard from '$lib/components/QuestionCard.svelte';
  import Sidebar from '$lib/components/Sidebar.svelte';
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
  let isLoading = true;
  let isUpdatingStatus = false;
  let errorMessage = '';

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

  const updateStatus = async (nextStatus: EventStatus) => {
    if (!event) return;

    isUpdatingStatus = true;
    errorMessage = '';

    try {
      const { error } = await supabase.from('events').update({ status: nextStatus }).eq('id', event.id);

      if (error) {
        throw error;
      }

      event = { ...event, status: nextStatus };
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to update event status.';
    } finally {
      isUpdatingStatus = false;
    }
  };

  const setupRealtime = () => {
    if (!event) return;

    questionChannel = supabase
      .channel(`questions-${event.id}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'questions', filter: `event_id=eq.${event.id}` },
        () => {
          void loadQuestions();
        }
      )
      .subscribe();

    statusChannel = supabase
      .channel(`event-status-${event.code}`)
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

  onMount(() => {
    let active = true;

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
      title="Host Panel"
      subtitle="Control event state and watch questions update live."
      links={[
        { label: 'Create another event', href: '/create' },
        { label: 'Go to landing', href: '/' }
      ]}
    >
      {#if event}
        <p class="muted-text text-xs uppercase tracking-[0.2em]">Room code</p>
    		<p class="display-accent mt-1 font-mono text-xl font-black tracking-widest">{event.code}</p>
      {/if}
    </Sidebar>

    <section>
      {#if isLoading}
        <div class="neon-panel p-6 text-sm muted-text">Loading event...</div>
      {:else if errorMessage}
        <div class="neon-panel p-6 text-sm text-rose-200">{errorMessage}</div>
      {:else if event}
        <EventCard event={event}>
          <div class="flex flex-wrap gap-2">
            <button
              type="button"
              onclick={() => updateStatus('live')}
              disabled={isUpdatingStatus || event.status === 'live'}
              class="btn-primary"
            >
              Start Event
            </button>
            <button
              type="button"
              onclick={() => updateStatus('closed')}
              disabled={isUpdatingStatus || event.status === 'closed'}
              class="rounded-xl bg-rose-500 px-5 py-3 text-sm font-semibold text-rose-50 transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-50"
            >
              Close Event
            </button>
          </div>
        </EventCard>

        <div class="mt-6 neon-panel p-5">
          <h3 class="theme-text text-lg font-black uppercase tracking-[0.12em]">Questions</h3>
          <p class="mt-1 text-sm muted-text">Ranked by votes in real time.</p>

          <div class="mt-4 space-y-3">
            {#if questions.length === 0}
              <p class="alert-info">No questions yet.</p>
            {:else}
              {#each questions as question (question.id)}
                <QuestionCard {question} />
              {/each}
            {/if}
          </div>
        </div>
      {/if}
    </section>
  </div>
</main>