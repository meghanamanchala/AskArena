<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let title = '';
  let hostName = '';
  let isSubmitting = false;
  let errorMessage = '';

  const generateCode = () => Math.random().toString(36).substring(2, 8).toUpperCase();

  const createEvent = async () => {
    errorMessage = '';
    isSubmitting = true;

    try {
      let attempts = 0;
      let createdCode = '';

      while (attempts < 5) {
        const code = generateCode();

        const { error } = await supabase.from('events').insert({
          title: title.trim(),
          host_name: hostName.trim(),
          code,
          status: 'waiting'
        });

        if (!error) {
          createdCode = code;
          break;
        }

        if (error.code !== '23505') {
          throw error;
        }

        attempts += 1;
      }

      if (!createdCode) {
        throw new Error('Could not generate a unique event code. Try again.');
      }

      await goto(`/event/${createdCode}`);
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to create event.';
    } finally {
      isSubmitting = false;
    }
  };
</script>

<main class="min-h-screen bg-slate-50 px-4 py-12">
  <div class="mx-auto max-w-xl rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
    <h1 class="text-2xl font-bold text-slate-900">Create Event</h1>
    <p class="mt-2 text-sm text-slate-600">Set up your Q&amp;A room and share the code with attendees.</p>

    <form
      class="mt-6 space-y-4"
      onsubmit={(event) => {
        event.preventDefault();
        void createEvent();
      }}
    >
      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700" for="title">Event title</label>
        <input
          id="title"
          type="text"
          required
          maxlength="120"
          bind:value={title}
          class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          placeholder="Weekly Product AMA"
        />
      </div>

      <div>
        <label class="mb-1 block text-sm font-medium text-slate-700" for="host">Host name</label>
        <input
          id="host"
          type="text"
          required
          maxlength="60"
          bind:value={hostName}
          class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          placeholder="Alex"
        />
      </div>

      {#if errorMessage}
        <p class="rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">{errorMessage}</p>
      {/if}

      <button
        type="submit"
        disabled={isSubmitting}
        class="w-full rounded-xl bg-indigo-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-slate-400"
      >
        {isSubmitting ? 'Creating...' : 'Create Event'}
      </button>
    </form>

    <a href="/" class="mt-5 inline-block text-sm font-medium text-indigo-700 hover:text-indigo-800">Back to home</a>
  </div>
</main>