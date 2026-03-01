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

<main class="min-h-screen bg-slate-50 px-4 py-8">
  <div class="mx-auto grid max-w-6xl gap-6 lg:grid-cols-[300px_1fr]">
    <Sidebar
      title="Host Panel"
      subtitle="Control event state and watch questions update live."
      links={[
        { label: 'Create another event', href: '/create' },
        { label: 'Go to landing', href: '/' }
      ]}
    >
      {#if event}
        <p class="text-sm text-slate-600">Room code</p>
        <p class="mt-1 font-mono text-xl font-black tracking-widest text-slate-900">{event.code}</p>
      {/if}
    </Sidebar>

    <section>
      {#if isLoading}
        <div class="rounded-2xl border border-slate-200 bg-white p-6 text-sm text-slate-600 shadow-sm">Loading event...</div>
      {:else if errorMessage}
        <div class="rounded-2xl border border-rose-200 bg-rose-50 p-6 text-sm text-rose-700 shadow-sm">{errorMessage}</div>
      {:else if event}
        <EventCard event={event}>
          <div class="flex flex-wrap gap-2">
            <button
              type="button"
              onclick={() => updateStatus('live')}
              disabled={isUpdatingStatus || event.status === 'live'}
              class="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-emerald-700 disabled:cursor-not-allowed disabled:bg-slate-400"
            >
              Start Event
            </button>
            <button
              type="button"
              onclick={() => updateStatus('closed')}
              disabled={isUpdatingStatus || event.status === 'closed'}
              class="rounded-lg bg-rose-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-rose-700 disabled:cursor-not-allowed disabled:bg-slate-400"
            >
              Close Event
            </button>
          </div>
        </EventCard>

        <div class="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <h3 class="text-lg font-bold text-slate-900">Questions</h3>
          <p class="mt-1 text-sm text-slate-600">Ranked by votes in real time.</p>

          <div class="mt-4 space-y-3">
            {#if questions.length === 0}
              <p class="rounded-lg bg-slate-50 px-4 py-3 text-sm text-slate-600">No questions yet.</p>
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