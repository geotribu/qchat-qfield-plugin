module.exports = async ({ github, context }) => {
  const prefix = process.env.TAG_PREFIX;
  const { data: releases } = await github.rest.repos.listReleases({
    owner: context.repo.owner,
    repo: context.repo.repo,
    per_page: 100,
  });
  const toDelete = releases.filter(
    (r) => r.prerelease && r.tag_name.startsWith(prefix),
  );
  console.log(
    `${toDelete.length} pre-release(s) to delete with prefix "${prefix}"`,
  );
  for (const release of toDelete) {
    await github.rest.repos.deleteRelease({
      owner: context.repo.owner,
      repo: context.repo.repo,
      release_id: release.id,
    });
    await github.rest.git.deleteRef({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: `tags/${release.tag_name}`,
    });
    console.log(`Deleted: ${release.tag_name}`);
  }
};
