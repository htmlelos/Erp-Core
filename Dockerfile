#Dockerfile

# Use official Bun image
FROM oven/bun AS base
WORKDIR /usr/src/app

# install dependencies into temp folder
# this will cache them and speed up builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lock /temp/dev/
RUN cd /temp/dev && bun install --frozen-lockfile

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lock /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# copy node_modules from temp folder
# then copy all (non-ignored) project files into the image
FROM install AS prerelease
COPY --from=install /temp/dev/node_modules ./node_modules
COPY . .

# [optional] test and build the app
# ENV NODE_ENV=production
# RUN bun test
# RUN bun build

# copy production dependencies and source code into the final image
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/index.ts .
COPY --from=prerelease /usr/src/app/package.json .

# run the app
USER bun
EXPOSE 3000
CMD ["bun", "run", "dev"]
